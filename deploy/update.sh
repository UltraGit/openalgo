#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Update Script
# ============================================================================
# Run this on the NAS directly or via SSH from your dev machine:
#
#   ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'
#
# What it does:
#   1. Pulls the latest code from GitHub (main branch)
#   2. Rebuilds the Docker image with the updated code
#   3. Restarts the container (zero-downtime not guaranteed — brief outage expected)
#   4. Tails logs so you can confirm a healthy startup
#
# Prerequisites:
#   - SSH access to the NAS as a user with Docker permissions
#   - Git remote 'origin' points to your fork on GitHub
#   - /volume1/docker/openalgo/env/.env exists and is configured
# ============================================================================

set -e

REPO_DIR="/volume1/docker/openalgo/repo"
COMPOSE_FILE="$REPO_DIR/docker-compose.nas.yml"

echo "=== OpenAlgo NAS Update ==="
echo "Repo:    $REPO_DIR"
echo "Compose: $COMPOSE_FILE"
echo ""

cd "$REPO_DIR"

echo "[1/3] Pulling latest from GitHub..."
git pull origin main

echo ""
echo "[2/3] Rebuilding and restarting container..."
docker compose -f "$COMPOSE_FILE" down
docker compose -f "$COMPOSE_FILE" up -d --build

echo ""
echo "[3/3] Done. Tailing logs (Ctrl+C to exit)..."
docker compose -f "$COMPOSE_FILE" logs -f openalgo
