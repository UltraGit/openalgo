"""
HELLO — Heartbeat logger.
Logs a startup banner then emits a timestamped heartbeat every 5 seconds.
Runs indefinitely so `docker compose logs -f` stays live.
"""
import time
import datetime


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [HELLO] {msg}", flush=True)


log("=" * 55)
log("OpenAlgo NAS Smoke Test — HELLO")
log("Container is alive and logging correctly.")
log("Tail with: docker compose -f docker-compose.smoke.yml logs -f")
log("=" * 55)

count = 0
while True:
    time.sleep(5)
    count += 1
    log(f"Heartbeat #{count} — still running")
