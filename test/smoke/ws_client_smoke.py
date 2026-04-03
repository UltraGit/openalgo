"""
E (ws) — WebSocket probe client.
Connects to the smoke-ws-server service, sends a PING message,
asserts the PONG response, then exits cleanly.
Exits 0 on PASS, 1 on FAIL.

Requires: websockets (installed inline by docker-compose.smoke.abce.yml)
"""
import asyncio
import sys
import datetime

# Resolves via Docker Compose internal DNS (service name = hostname)
TARGET = "ws://smoke-ws-server:8765"
PING_MSG = "hello from ws_client_smoke"
EXPECTED_PONG = f"PONG: {PING_MSG}"
CONNECT_TIMEOUT = 10.0  # seconds — server may still be starting
RECV_TIMEOUT = 5.0


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [WS-CLI] {msg}", flush=True)


async def main():
    import websockets  # installed by compose entrypoint

    log("=" * 55)
    log("E (ws): WebSocket client probe")
    log(f"Target: {TARGET}")
    log("=" * 55)

    try:
        log(f"Connecting to {TARGET} ...")
        async with websockets.connect(TARGET, open_timeout=CONNECT_TIMEOUT) as ws:
            log("WS CONNECTED OK")

            log(f"Sending: '{PING_MSG}'")
            await ws.send(PING_MSG)

            response = await asyncio.wait_for(ws.recv(), timeout=RECV_TIMEOUT)
            log(f"Received: '{response}'")

            if response == EXPECTED_PONG:
                log("WS PASS ✓ — server is reachable and responding correctly")
            else:
                log(f"WS FAIL ✗ — unexpected response (expected '{EXPECTED_PONG}')")
                sys.exit(1)

    except asyncio.TimeoutError:
        log(f"WS FAIL ✗ — timed out connecting to {TARGET}")
        log("  Check: smoke-ws-server container started successfully")
        log("  Check: depends_on / sleep in compose gives server time to start")
        sys.exit(1)
    except Exception as exc:
        log(f"WS FAIL ✗ — {exc}")
        sys.exit(1)


asyncio.run(main())
