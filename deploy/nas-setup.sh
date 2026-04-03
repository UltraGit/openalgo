#!/bin/bash
# ============================================================================
# OpenAlgo NAS — One-Time Setup Script
# ============================================================================
# Run ONCE on the NAS via SSH to initialise the directory structure and
# clone the repository.
#
# Usage:
#   ssh nas
#   bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_FORK/openalgo/main/deploy/nas-setup.sh)
#
# Or copy the script to the NAS first, then:
#   ssh nas 'bash /tmp/nas-setup.sh'
#
# Prerequisites:
#   - Docker and Git installed on the NAS (via Synology Package Center)
#   - SSH access as admin or a user with Docker permissions
#   - Your forked repo URL ready
# ============================================================================

set -e

NAS_ROOT="/volume1/docker/openalgo"
REPO_DIR="$NAS_ROOT/repo"
REPO_URL="${REPO_URL:-https://github.com/YOUR_GITHUB_USER/openalgo.git}"

echo "=== OpenAlgo NAS — One-Time Setup ==="
echo "NAS root: $NAS_ROOT"
echo "Repo URL: $REPO_URL"
echo ""

# ----------------------------------------------------------------------------
# 1. Create directory structure
# ----------------------------------------------------------------------------
echo "[1/4] Creating directory structure..."
mkdir -p "$NAS_ROOT/db"
mkdir -p "$NAS_ROOT/log"
mkdir -p "$NAS_ROOT/strategies/scripts"
mkdir -p "$NAS_ROOT/keys"
mkdir -p "$NAS_ROOT/tmp"
mkdir -p "$NAS_ROOT/env"

# Keys directory should be owner-only
chmod 700 "$NAS_ROOT/keys"
# env directory holds secrets — restrict to owner
chmod 700 "$NAS_ROOT/env"

echo "    Created:"
echo "      $NAS_ROOT/db"
echo "      $NAS_ROOT/log"
echo "      $NAS_ROOT/strategies"
echo "      $NAS_ROOT/keys"
echo "      $NAS_ROOT/tmp"
echo "      $NAS_ROOT/env  (secrets go here)"

# ----------------------------------------------------------------------------
# 2. Clone repository
# ----------------------------------------------------------------------------
echo ""
echo "[2/4] Cloning repository to $REPO_DIR..."

if [ -d "$REPO_DIR/.git" ]; then
    echo "    Repo already exists — skipping clone. Run 'git pull' to update."
else
    git clone "$REPO_URL" "$REPO_DIR"
    echo "    Cloned successfully."
fi

# ----------------------------------------------------------------------------
# 3. Remind user to configure .env
# ----------------------------------------------------------------------------
echo ""
echo "[3/4] Configure your environment file..."
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  ACTION REQUIRED: Create and populate your .env file            │"
echo "  │                                                                 │"
echo "  │  cp $REPO_DIR/env.nas.sample $NAS_ROOT/env/.env                │"
echo "  │  nano $NAS_ROOT/env/.env                                        │"
echo "  │                                                                 │"
echo "  │  Mandatory values to set:                                       │"
echo "  │    APP_KEY          (run: python3 -c \"import secrets;           │"
echo "  │                      print(secrets.token_hex(32))\")             │"
echo "  │    API_KEY_PEPPER   (generate a second key the same way)        │"
echo "  │    HOST_SERVER      http://192.168.1.72:8080                    │"
echo "  │    WEBSOCKET_URL    ws://192.168.1.72:8765                      │"
echo "  └─────────────────────────────────────────────────────────────────┘"

# ----------------------------------------------------------------------------
# 4. Print start command
# ----------------------------------------------------------------------------
echo ""
echo "[4/4] When your .env is ready, start OpenAlgo with:"
echo ""
echo "  cd $REPO_DIR"
echo "  docker compose -f docker-compose.nas.yml up -d --build"
echo ""
echo "  Then open: http://192.168.1.72:8080"
echo ""
echo "=== Setup complete ==="
