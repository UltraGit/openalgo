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
REPO_URL="${REPO_URL:-https://github.com/UltraGit/openalgo.git}"

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
# 2. Clone repository and checkout deploy branch
# ----------------------------------------------------------------------------
echo ""
echo "[2/4] Cloning repository to $REPO_DIR..."

DEPLOY_BRANCH="${DEPLOY_BRANCH:-develop}"

if [ -d "$REPO_DIR/.git" ]; then
    echo "    Repo already exists — pulling latest and switching to $DEPLOY_BRANCH..."
    cd "$REPO_DIR"
    git fetch --tags origin
    git checkout "$DEPLOY_BRANCH" 2>/dev/null || \
        git checkout -b "$DEPLOY_BRANCH" --track "origin/$DEPLOY_BRANCH"
    git pull origin "$DEPLOY_BRANCH"
else
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    # Checkout the deploy branch so env.nas.sample and all NAS files are present.
    # main tracks upstream OpenAlgo only — our deploy layer lives on develop.
    echo "    Checking out branch: $DEPLOY_BRANCH"
    git checkout "$DEPLOY_BRANCH" 2>/dev/null || \
        git checkout -b "$DEPLOY_BRANCH" --track "origin/$DEPLOY_BRANCH"
    git fetch --tags origin
fi

# Show repo state and available release tags
CURRENT=$(git rev-parse --abbrev-ref HEAD)
SHORT=$(git rev-parse --short HEAD)
echo "    Repo ready: branch '$CURRENT' @ $SHORT"

TAGS=$(git tag -l 'nas/*' | sort -V)
if [ -n "$TAGS" ]; then
    echo "    Available release tags:"
    echo "$TAGS" | sed 's/^/      /'
else
    echo "    No release tags yet — cut one from WSL with: ./deploy/release.sh 0.1"
fi

# ----------------------------------------------------------------------------
# 3. Remind user to configure .env
# ----------------------------------------------------------------------------
echo ""
echo "[3/4] Configure your environment file..."

# env.nas.sample is only present on develop (not main) — confirm it's there
if [ -f "$REPO_DIR/env.nas.sample" ]; then
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
else
    echo ""
    echo "  WARNING: env.nas.sample not found — repo may be on the wrong branch."
    echo "  Expected branch: $DEPLOY_BRANCH"
    echo "  Current branch:  $(git rev-parse --abbrev-ref HEAD)"
    echo "  Manually create $NAS_ROOT/env/.env from the template in the repo."
fi

# ----------------------------------------------------------------------------
# 4. Print start command
# ----------------------------------------------------------------------------
echo ""
echo "[4/4] When your .env is ready, deploy from WSL with:"
echo ""
echo "  # Deploy latest develop branch:"
echo "  ssh nas '$REPO_DIR/deploy/update.sh'"
echo ""
echo "  # Or deploy a specific release tag:"
echo "  ./deploy/deploy-tag.sh nas/v0.1"
echo ""
echo "  Then open: http://192.168.1.72:8080"
echo ""
echo "=== Setup complete ==="
