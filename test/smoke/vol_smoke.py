"""
A (vol) — Volume mount read/write test.
Writes a file to /app/db (bind-mounted from /volume1/docker/openalgo/db/),
reads it back, then removes it.
Exits 0 on PASS, 1 on FAIL.
"""
import os
import sys
import datetime

DB_PATH = os.environ.get("DB_PATH", "/tmp/db")
TEST_FILE = os.path.join(DB_PATH, "smoke_vol_test.txt")
TIMESTAMP = datetime.datetime.now().isoformat()


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [VOL] {msg}", flush=True)


log("=" * 55)
log("A (vol): Volume mount test — /app/db")
log("=" * 55)

try:
    # Confirm mount point exists
    if not os.path.isdir(DB_PATH):
        raise RuntimeError(f"{DB_PATH} does not exist — volume not mounted")
    log(f"Mount point exists: {DB_PATH}")

    # Write
    payload = f"smoke test written at {TIMESTAMP}\n"
    with open(TEST_FILE, "w") as f:
        f.write(payload)
    log(f"WRITE OK: {TEST_FILE}")

    # Read back
    with open(TEST_FILE, "r") as f:
        content = f.read()
    assert content == payload, "Content mismatch after read-back"
    log(f"READ OK: '{content.strip()}'")

    # Cleanup
    os.remove(TEST_FILE)
    assert not os.path.exists(TEST_FILE), "File still exists after removal"
    log("CLEANUP OK: test file removed")

    log("VOL PASS ✓ — volume is mounted, readable and writable")

except Exception as exc:
    log(f"VOL FAIL ✗ — {exc}")
    log(f"  Check: /volume1/docker/openalgo/db/ exists on NAS")
    log(f"  Check: NAS user has write permission on that directory")
    sys.exit(1)
