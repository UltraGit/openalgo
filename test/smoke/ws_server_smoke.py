"""
E (ws) — WebSocket echo server.
Listens on 0.0.0.0:8765, echoes messages back as PONG: <message>.
The ws_client_smoke.py probe connects to this and verifies round-trip.
Also exposed on the NAS at port 8765 so it can be tested from WSL too.

Requires: websockets (installed inline by docker-compose.smoke.abce.yml)
"""
import asyncio
import datetime


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [WS-SRV] {msg}", flush=True)


async def handler(websocket):
    peer = websocket.remote_address
    log(f"Client connected: {peer}")
    try:
        async for message in websocket:
            log(f"Received from {peer}: '{message}'")
            response = f"PONG: {message}"
            await websocket.send(response)
            log(f"Sent to {peer}: '{response}'")
    except Exception as exc:
        log(f"Connection error from {peer}: {exc}")
    finally:
        log(f"Client disconnected: {peer}")


async def main():
    import websockets  # installed by compose entrypoint

    log("=" * 55)
    log("E (ws): WebSocket echo server on 0.0.0.0:8765")
    log("From WSL, test with: wscat -c ws://192.168.1.72:8765")
    log("(or let ws_client_smoke.py run the automated probe)")
    log("=" * 55)

    async with websockets.serve(handler, "0.0.0.0", 8765):
        log("WS server ready — waiting for connections...")
        await asyncio.Future()  # run forever


asyncio.run(main())
