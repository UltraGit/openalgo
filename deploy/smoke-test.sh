#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Smoke Test Runner
# ============================================================================
# Run from WSL to deploy a smoke variant to the NAS, tail its logs,
# run any WSL-side checks (port curl, etc.), then optionally tear down.
#
# Usage:
#   ./deploy/smoke-test.sh [hello|abc|abce]
#
#   hello  — HELLO only (heartbeat logger, no ports/volumes required)
#   abc    — HELLO + A/vol + B/port + C/env  (requires db/ and env/.env on NAS)
#   abce   — HELLO + A/vol + B/port + C/env + E/ws  (as above + WebSocket probe)
#
# Prerequisites:
#   - SSH key auth to NAS:  ssh-copy-id admin@192.168.1.72
#   - For abc/abce: NAS setup complete (deploy/nas-setup.sh has been run)
#   - For abc/abce: /volume1/docker/openalgo/env/.env populated
#
# What this script does:
#   1. SSHs to NAS and brings up the chosen compose variant
#   2. Streams all container logs to your terminal
#   3. (abc/abce) Curls port 8080 from WSL to verify B/port
#   4. (abce)     Runs a WebSocket round-trip from WSL to verify E/ws externally
#   5. Prompts to tear down containers when you press Ctrl+C or finish tailing
# ============================================================================

set -euo pipefail

NAS_HOST="admin@192.168.1.72"
REPO_DIR="/volume1/docker/openalgo/repo"
VARIANT="${1:-hello}"
LOG_TAIL_SECS="${LOG_TAIL_SECS:-60}"   # how long to tail before prompting cleanup

case "$VARIANT" in
  hello) COMPOSE_FILE="docker-compose.smoke.yml" ;;
  abc)   COMPOSE_FILE="docker-compose.smoke.abc.yml" ;;
  abce)  COMPOSE_FILE="docker-compose.smoke.abce.yml" ;;
  *)
    echo "ERROR: Unknown variant '${VARIANT}'. Use: hello | abc | abce"
    exit 1
    ;;
esac

COMPOSE_CMD="docker compose -f ${REPO_DIR}/${COMPOSE_FILE}"

# ---- helpers ----------------------------------------------------------------

section() { echo ""; echo "=== $* ==="; }
pass()    { echo "  PASS ✓  $*"; }
fail()    { echo "  FAIL ✗  $*"; }

cleanup() {
    section "Cleanup"
    read -rp "Stop and remove smoke containers on NAS? [y/N] " yn
    if [[ "${yn,,}" =~ ^y ]]; then
        ssh "${NAS_HOST}" "${COMPOSE_CMD} down" && echo "  Containers removed."
    else
        echo "  Containers left running. To remove:"
        echo "    ssh ${NAS_HOST} '${COMPOSE_CMD} down'"
    fi
}

# ---- main -------------------------------------------------------------------

section "OpenAlgo Smoke Test — variant: ${VARIANT}"
echo "  NAS:     ${NAS_HOST}"
echo "  Compose: ${COMPOSE_FILE}"

# 1. Start containers on NAS
section "1/4  Starting containers on NAS"
ssh "${NAS_HOST}" "cd ${REPO_DIR} && ${COMPOSE_CMD} up -d"
echo "  Containers started."

# 2. WSL-side port check (B) — give server 3s to bind
if [[ "${VARIANT}" == "abc" || "${VARIANT}" == "abce" ]]; then
    section "2/4  B/port — curl http://192.168.1.72:8080/ from WSL"
    sleep 3
    HTTP_BODY=$(curl -sf --max-time 5 "http://192.168.1.72:8080/" 2>&1 || true)
    if echo "${HTTP_BODY}" | grep -q "PORT OK"; then
        pass "port 8080 reachable from WSL. Response: '${HTTP_BODY}'"
    else
        fail "port 8080 not reachable or unexpected response: '${HTTP_BODY}'"
        echo "       Check: NAS firewall / Synology port forwarding rules"
    fi
else
    section "2/4  B/port — skipped (hello variant)"
fi

# 3. WSL-side WebSocket probe (E)
if [[ "${VARIANT}" == "abce" ]]; then
    section "3/4  E/ws — WebSocket round-trip from WSL (ws://192.168.1.72:8765)"
    # Wait for ws-server pip install + startup (~12s total)
    echo "  Waiting 15s for ws-server to start..."
    sleep 15
    # Use Python's built-in asyncio + websockets if available, else skip
    WS_RESULT=$(python3 - <<'PYEOF' 2>&1 || echo "SKIP"
import asyncio, sys
try:
    import websockets
except ImportError:
    print("SKIP: websockets not installed in WSL — run: pip install websockets")
    sys.exit(0)

async def probe():
    try:
        async with websockets.connect("ws://192.168.1.72:8765", open_timeout=8) as ws:
            await ws.send("wsl-side probe")
            resp = await asyncio.wait_for(ws.recv(), timeout=5)
            print(f"Response: '{resp}'")
            if "PONG" in resp:
                print("WS WSL-SIDE PASS")
            else:
                print("WS WSL-SIDE FAIL: unexpected response")
    except Exception as e:
        print(f"WS WSL-SIDE FAIL: {e}")

asyncio.run(probe())
PYEOF
    )
    if echo "${WS_RESULT}" | grep -q "PASS"; then
        pass "WebSocket reachable from WSL. ${WS_RESULT}"
    elif echo "${WS_RESULT}" | grep -q "SKIP"; then
        echo "  SKIP — ${WS_RESULT}"
    else
        fail "WebSocket not reachable from WSL. ${WS_RESULT}"
        echo "       Check: port 8765 open in NAS firewall"
    fi
else
    section "3/4  E/ws — skipped (hello or abc variant)"
fi

# 4. Tail container logs
section "4/4  Container logs — streaming (Ctrl+C to stop)"
echo "  Tailing for ${LOG_TAIL_SECS}s then prompting for cleanup..."
echo "  (Press Ctrl+C at any time to skip to cleanup)"
echo ""

trap cleanup EXIT

ssh "${NAS_HOST}" "${COMPOSE_CMD} logs -f" &
SSH_PID=$!
sleep "${LOG_TAIL_SECS}" && kill "${SSH_PID}" 2>/dev/null || true
wait "${SSH_PID}" 2>/dev/null || true
