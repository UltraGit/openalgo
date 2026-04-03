"""
C (env) — .env file loading and parsing test.
Reads the .env file (path from ENV_FILE env var, default /app/env_host/.env).
The env directory is bind-mounted rather than the file directly — Synology
AUFS cannot mount a single file unless it already exists in the image.
Exits 0 on PASS, 1 on FAIL.
"""
import os
import sys
import datetime

ENV_FILE = os.environ.get("ENV_FILE", "/app/env_host/.env")

# Keys safe to print (no credentials or secrets)
SAFE_KEYS = [
    "FLASK_PORT",
    "FLASK_HOST_IP",
    "FLASK_DEBUG",
    "FLASK_ENV",
    "PORT",
    "WEBSOCKET_PORT",
    "WEBSOCKET_HOST",
    "ZMQ_PORT",
    "ZMQ_HOST",
    "TRADING_MODE",
    "DATABASE_URL",
    "HOST_SERVER",
    "LOG_LEVEL",
    "LOG_TO_FILE",
    "LOG_RETENTION",
]


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [ENV] {msg}", flush=True)


def parse_env_file(path):
    """Parse KEY = 'value' and KEY=value formats. Skip comments and blanks."""
    result = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, val = line.partition("=")
            result[key.strip()] = val.strip().strip("'\"")
    return result


log("=" * 55)
log("C (env): .env file loading test")
log(f"Target: {ENV_FILE}")
log("=" * 55)

try:
    if not os.path.exists(ENV_FILE):
        raise FileNotFoundError(
            f"{ENV_FILE} not found — check the volume mount in docker-compose.smoke.abc.yml"
        )
    log(f"File exists: {ENV_FILE}")

    env_vals = parse_env_file(ENV_FILE)
    log(f"Parsed {len(env_vals)} keys from .env")

    log("Non-secret key values:")
    missing = []
    for key in SAFE_KEYS:
        val = env_vals.get(key)
        if val is not None:
            log(f"  {key:<25} = {val}")
        else:
            missing.append(key)

    if missing:
        log(f"Keys not set (may be optional): {', '.join(missing)}")

    # Warn if critical secrets are still placeholder values
    for secret_key in ("APP_KEY", "API_KEY_PEPPER"):
        val = env_vals.get(secret_key, "")
        if "change_me" in val.lower():
            log(f"WARNING: {secret_key} still has placeholder value — update before deploy")

    log("ENV PASS ✓ — .env is readable and parseable")

except Exception as exc:
    log(f"ENV FAIL ✗ — {exc}")
    log("  Check: /volume1/docker/openalgo/env/.env exists on NAS")
    log("  Check: file was copied from env.nas.sample and filled in")
    sys.exit(1)
