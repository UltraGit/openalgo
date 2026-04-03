#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Environment Validation Script
# ============================================================================
# Run from WSL before any deployment to confirm the NAS is ready.
# Does NOT start any containers — read-only inspection only.
#
# Usage:
#   ./deploy/nas-check.sh
#
# Checks performed:
#   LOCAL  0  ~/.ssh/config has 'nas' alias
#   LOCAL  1  NAS reachable (ping)
#   LOCAL  2  SSH connection via 'nas' alias (BatchMode — no prompts)
#   NAS    3  Docker daemon running
#   NAS    4  Docker Compose available
#   NAS    5  Git installed
#   NAS    6  Repo cloned at expected path
#   NAS    7  Repo current branch / tag
#   NAS    8  Required directories exist
#   NAS    9  .env file present and non-empty
#   NAS   10  .env has no placeholder secrets
#   NAS   11  Ports 8080 / 8765 / 5555 are free
#   NAS   12  Disk space on /volume1 (warns if < 3 GB free)
#   NAS   13  Existing openalgo containers (name conflicts)
#   NAS   14  Existing openalgo Docker images (cache state)
#
# Exit code: 0 = all checks passed, 1 = one or more failures
# ============================================================================

set -uo pipefail

NAS_HOST="nas"
NAS_IP="192.168.1.72"   # explicit IP for ping (SSH alias not usable here)
NAS_ROOT="/volume1/docker/openalgo"
REPO_DIR="${NAS_ROOT}/repo"
ENV_FILE="${NAS_ROOT}/env/.env"
REQUIRED_PORTS=(8080 8765 5555)
MIN_FREE_GB=3

PASS=0
FAIL=0

# ---- output helpers ---------------------------------------------------------

section() { printf "\n=== %s ===\n" "$*"; }
pass()    { printf "  PASS \u2713  %s\n" "$*"; (( PASS++ )); }
fail()    { printf "  FAIL \u2717  %s\n" "$*"; (( FAIL++ )); }
info()    { printf "  INFO    %s\n" "$*"; }
warn()    { printf "  WARN \u26a0  %s\n" "$*"; }

# ---- check helpers ----------------------------------------------------------

check() {
    # check <label> <command...>
    # Runs command, prints PASS/FAIL based on exit code.
    local label="$1"; shift
    if "$@" &>/dev/null; then
        pass "$label"
        return 0
    else
        fail "$label"
        return 1
    fi
}

# ---- local checks -----------------------------------------------------------

section "Local checks"

# 0. SSH config alias
if ssh -G nas 2>/dev/null | grep -qi "hostname 192.168.1.72"; then
    pass "SSH config: 'nas' alias → 192.168.1.72 (IdentityFile: $(ssh -G nas 2>/dev/null | awk '/^identityfile/{print $2; exit}'))"
else
    fail "SSH config: 'nas' alias not found in ~/.ssh/config"
    echo "  Add it with:"
    echo "    echo -e '\\nHost nas\\n  HostName 192.168.1.72\\n  User thorn\\n  IdentityFile ~/.ssh/nas_key\\n  IdentitiesOnly yes' >> ~/.ssh/config"
    echo "    chmod 600 ~/.ssh/config"
fi

# 1. Ping
if ping -c1 -W2 "$NAS_IP" &>/dev/null; then
    pass "NAS reachable at $NAS_IP"
else
    fail "NAS not reachable at $NAS_IP — check network / NAS power"
    echo ""
    echo "Cannot continue — NAS is unreachable."
    exit 1
fi

# 2. SSH (BatchMode — will not prompt for passphrase or password)
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$NAS_HOST" true 2>/dev/null; then
    pass "SSH connection via 'nas' alias (key auth, no password prompt)"
else
    fail "SSH BatchMode failed — key not accepted by NAS"
    echo "  Fix: push your public key to the NAS (password prompt — last time):"
    echo "    cat ~/.ssh/nas_key.pub | ssh thorn@192.168.1.72 \\"
    echo "      'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'"
    echo "  Then retry: ssh -o BatchMode=yes nas true"
    echo ""
    echo "Cannot continue — SSH key auth required for NAS checks."
    exit 1
fi

# ---- NAS-side checks (single SSH session) -----------------------------------

section "NAS checks (via SSH)"

# Run all NAS checks in one session; each prints a structured result line.
NAS_OUTPUT=$(ssh -o ConnectTimeout=10 "$NAS_HOST" bash <<REMOTE
set -uo pipefail

# Synology non-interactive shells omit /usr/local/bin from PATH
export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"

NAS_ROOT="${NAS_ROOT}"
REPO_DIR="${REPO_DIR}"
ENV_FILE="${ENV_FILE}"
REQUIRED_PORTS=(${REQUIRED_PORTS[*]})
MIN_FREE_GB=${MIN_FREE_GB}

p() { printf "PASS|%s\n" "\$*"; }
f() { printf "FAIL|%s\n" "\$*"; }
i() { printf "INFO|%s\n" "\$*"; }
w() { printf "WARN|%s\n" "\$*"; }

# 3. Docker daemon
if docker info &>/dev/null; then
    p "Docker daemon running"
else
    f "Docker daemon not running — start it in Synology Container Manager"
fi

# 4. Docker Compose
if docker compose version &>/dev/null; then
    VER=\$(docker compose version --short 2>/dev/null || echo "unknown")
    p "Docker Compose available (v\${VER})"
else
    f "Docker Compose not available — update Synology Container Manager"
fi

# 5. Git
if command -v git &>/dev/null; then
    VER=\$(git --version | awk '{print \$3}')
    p "Git installed (v\${VER})"
else
    f "Git not found — install via Synology Package Center"
fi

# 6. Repo cloned
if [ -d "\${REPO_DIR}/.git" ]; then
    p "Repo present at \${REPO_DIR}"
else
    f "Repo not found at \${REPO_DIR} — run deploy/nas-setup.sh first"
fi

# 7. Repo state (branch / tag / detached)
if [ -d "\${REPO_DIR}/.git" ]; then
    cd "\${REPO_DIR}"
    BRANCH=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    SHORT=\$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    if [ "\${BRANCH}" = "HEAD" ]; then
        TAG=\$(git describe --tags --exact-match HEAD 2>/dev/null || echo "detached")
        i "Repo state: detached at \${TAG} (\${SHORT})"
    else
        i "Repo state: branch '\${BRANCH}' @ \${SHORT}"
    fi
    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        i "Working tree: clean"
    else
        w "Working tree has uncommitted changes"
    fi
fi

# 8. Required directories
for DIR in "\${NAS_ROOT}/db" "\${NAS_ROOT}/log" "\${NAS_ROOT}/env" \
           "\${NAS_ROOT}/strategies" "\${NAS_ROOT}/keys" "\${NAS_ROOT}/tmp"; do
    SHORT_DIR="\${DIR#${NAS_ROOT}/}"
    if [ -d "\${DIR}" ]; then
        # Check write permission
        if [ -w "\${DIR}" ]; then
            p "Directory \${SHORT_DIR}/ exists and is writable"
        else
            f "Directory \${SHORT_DIR}/ exists but is NOT writable — check permissions"
        fi
    else
        f "Directory \${SHORT_DIR}/ missing — run deploy/nas-setup.sh"
    fi
done

# 9. .env file exists and is non-empty
if [ -f "\${ENV_FILE}" ] && [ -s "\${ENV_FILE}" ]; then
    LINE_COUNT=\$(wc -l < "\${ENV_FILE}")
    p ".env file present (\${LINE_COUNT} lines)"
else
    if [ ! -f "\${ENV_FILE}" ]; then
        f ".env not found at \${ENV_FILE} — copy from env.nas.sample"
    else
        f ".env exists but is empty — populate from env.nas.sample"
    fi
fi

# 10. No placeholder secrets in .env
if [ -f "\${ENV_FILE}" ] && [ -s "\${ENV_FILE}" ]; then
    PLACEHOLDERS=\$(grep -c "change_me" "\${ENV_FILE}" 2>/dev/null || true)
    if [ "\${PLACEHOLDERS}" -eq 0 ]; then
        p ".env has no placeholder 'change_me' values"
    else
        f ".env still has \${PLACEHOLDERS} placeholder value(s) — generate real secrets"
    fi
fi

# 11. Port availability
for PORT in "\${REQUIRED_PORTS[@]}"; do
    if ss -tlnp 2>/dev/null | grep -q ":\${PORT} " || \
       netstat -tlnp 2>/dev/null | grep -q ":\${PORT} "; then
        # Check if it's one of our own containers
        OWNER=\$(ss -tlnp 2>/dev/null | grep ":\${PORT} " | grep -o 'users:(([^)]*))' || true)
        f "Port \${PORT} already in use \${OWNER}"
    else
        p "Port \${PORT} is free"
    fi
done

# 12. Disk space
FREE_KB=\$(df "\${NAS_ROOT}" 2>/dev/null | awk 'NR==2{print \$4}' || echo 0)
FREE_GB=\$(( FREE_KB / 1024 / 1024 ))
if [ "\${FREE_GB}" -ge "\${MIN_FREE_GB}" ]; then
    p "Disk space: \${FREE_GB} GB free on \$(df \${NAS_ROOT} | awk 'NR==2{print \$1}')"
else
    f "Disk space low: only \${FREE_GB} GB free (minimum ${MIN_FREE_GB} GB required)"
fi

# 13. Container name conflicts
CONFLICTS=()
for NAME in openalgo openalgo-smoke-hello openalgo-smoke-vol \
            openalgo-smoke-port openalgo-smoke-env \
            openalgo-smoke-ws-server openalgo-smoke-ws-client; do
    STATUS=\$(docker inspect --format '{{.State.Status}}' "\${NAME}" 2>/dev/null || true)
    if [ -n "\${STATUS}" ]; then
        CONFLICTS+=("\${NAME}=\${STATUS}")
    fi
done
if [ \${#CONFLICTS[@]} -eq 0 ]; then
    p "No conflicting containers found"
else
    for C in "\${CONFLICTS[@]}"; do
        NAME="\${C%%=*}"; STATE="\${C##*=}"
        if [ "\${STATE}" = "running" ]; then
            w "Container '\${NAME}' is already running (state: \${STATE})"
        else
            i "Container '\${NAME}' exists (state: \${STATE}) — will be replaced on deploy"
        fi
    done
fi

# 14. Existing openalgo images
IMAGES=\$(docker images --format "{{.Repository}}:{{.Tag}}  ({{.Size}}, {{.CreatedSince}})" 2>/dev/null \
         | grep -i "openalgo" || true)
if [ -n "\${IMAGES}" ]; then
    i "Existing OpenAlgo images (rebuild will use cache):"
    while IFS= read -r IMG; do
        i "  \${IMG}"
    done <<< "\${IMAGES}"
else
    i "No existing OpenAlgo images — first build will take longer"
fi

REMOTE
)

# ---- parse and display NAS results ------------------------------------------

while IFS='|' read -r TYPE MSG; do
    case "$TYPE" in
        PASS) pass "$MSG" ;;
        FAIL) fail "$MSG" ;;
        INFO) info "$MSG" ;;
        WARN) warn "$MSG" ;;
    esac
done <<< "$NAS_OUTPUT"

# ---- summary ----------------------------------------------------------------

section "Summary"
TOTAL=$(( PASS + FAIL ))
echo "  Checks passed: $PASS / $TOTAL"

if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "  All checks passed. NAS is ready for deployment."
    echo ""
    echo "  Next steps:"
    echo "    Smoke test:  ./deploy/smoke-test.sh hello"
    echo "    Deploy:      ./deploy/update.sh   (or ./deploy/deploy-tag.sh nas/vX.Y)"
    echo ""
    exit 0
else
    echo "  Checks failed:  $FAIL / $TOTAL"
    echo ""
    echo "  Resolve the FAIL items above before deploying."
    echo "  See deploy/RELEASE.md for setup instructions."
    echo ""
    exit 1
fi
