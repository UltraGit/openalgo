#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Update Script
# ============================================================================
# Run this on the NAS directly or via SSH from your dev machine:
#
#   ssh nas '/volume1/docker/openalgo/repo/deploy/update.sh'
#
# Deploy a specific release tag:
#   ssh nas \
#     'DEPLOY_TAG=nas/v0.1 /volume1/docker/openalgo/repo/deploy/update.sh'
#
# Deploy a specific branch (e.g. during development):
#   ssh nas \
#     'DEPLOY_BRANCH=develop /volume1/docker/openalgo/repo/deploy/update.sh'
#
# Priority: DEPLOY_TAG > DEPLOY_BRANCH > default (develop)
#
# What it does:
#   1. Fetches latest tags and commits from GitHub
#   2. Checks out the target tag or pulls the target branch
#   3. Rebuilds the Docker image
#   4. Restarts the container (brief outage expected)
#   5. Tails logs so you can confirm a healthy startup
#
# Prerequisites:
#   - SSH access to the NAS as a user with Docker permissions
#   - Git remote 'origin' points to your fork on GitHub
#   - /volume1/docker/openalgo/env/.env exists and is configured
# ============================================================================

set -euo pipefail

# Synology non-interactive SSH sessions omit /usr/local/bin (where docker lives)
export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"

REPO_DIR="/volume1/docker/openalgo/repo"
COMPOSE_FILE="$REPO_DIR/docker-compose.nas.yml"

# Resolve deploy target: tag takes precedence over branch
DEPLOY_TAG="${DEPLOY_TAG:-}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-develop}"

echo "=== OpenAlgo NAS Update ==="
echo "Repo:    $REPO_DIR"
echo "Compose: $COMPOSE_FILE"
if [ -n "$DEPLOY_TAG" ]; then
    echo "Target:  tag  → $DEPLOY_TAG"
else
    echo "Target:  branch → $DEPLOY_BRANCH"
fi
echo ""

cd "$REPO_DIR"

# ----------------------------------------------------------------------------
# 0. Preflight — .env must exist before we attempt a container start
# ----------------------------------------------------------------------------
ENV_FILE="/volume1/docker/openalgo/env/.env"
if [ ! -f "$ENV_FILE" ] || [ ! -s "$ENV_FILE" ]; then
    echo "ERROR: .env not found or empty at $ENV_FILE"
    echo "  Copy the template and fill in your secrets:"
    echo "    cp $REPO_DIR/env.nas.sample $ENV_FILE"
    echo "    nano $ENV_FILE"
    exit 1
fi
echo "  .env found: $ENV_FILE"

# ----------------------------------------------------------------------------
# 1. Fetch — always get latest tags and commits from origin
# ----------------------------------------------------------------------------
echo "[1/3] Fetching from GitHub..."
git fetch --tags --force origin

if [ -n "$DEPLOY_TAG" ]; then
    # Verify the tag exists
    if ! git tag -l | grep -qx "$DEPLOY_TAG"; then
        echo "ERROR: tag '$DEPLOY_TAG' not found (checked after fetch)."
        echo "  Available nas/ tags:"
        git tag -l 'nas/*' | sort -V | sed 's/^/    /'
        exit 1
    fi
    echo "  Checking out tag: $DEPLOY_TAG"
    git checkout --detach "$DEPLOY_TAG"
    DEPLOYED="$DEPLOY_TAG"
else
    # Pull latest of the target branch
    git checkout "$DEPLOY_BRANCH"
    git pull origin "$DEPLOY_BRANCH"
    DEPLOYED="$DEPLOY_BRANCH @ $(git rev-parse --short HEAD)"
fi

echo "  Deployed target: $DEPLOYED"

# ----------------------------------------------------------------------------
# 2. Rebuild and restart
# ----------------------------------------------------------------------------
echo ""
echo "[2/3] Rebuilding and restarting container..."
docker compose -f "$COMPOSE_FILE" down
docker compose -f "$COMPOSE_FILE" up -d --build

# ----------------------------------------------------------------------------
# 3. Tail logs
# ----------------------------------------------------------------------------
echo ""
echo "[3/3] Done — deployed: $DEPLOYED"
echo "Tailing logs (Ctrl+C to exit)..."
docker compose -f "$COMPOSE_FILE" logs -f openalgo
