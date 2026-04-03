#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Deploy a Specific Release Tag
# ============================================================================
# Convenience wrapper: runs update.sh on the NAS with DEPLOY_TAG set.
#
# Usage (from WSL):
#   ./deploy/deploy-tag.sh nas/v0.1
#
# Equivalent manual command:
#   ssh thorn@192.168.1.72 \
#     'DEPLOY_TAG=nas/v0.1 /volume1/docker/openalgo/repo/deploy/update.sh'
# ============================================================================

set -euo pipefail

TAG="${1:?Usage: ./deploy/deploy-tag.sh <tag>   e.g. nas/v0.1}"
NAS_HOST="thorn@192.168.1.72"
UPDATE_SCRIPT="/volume1/docker/openalgo/repo/deploy/update.sh"

echo "=== Deploying $TAG to NAS ==="
echo "  Host:   $NAS_HOST"
echo "  Script: $UPDATE_SCRIPT"
echo ""

ssh "$NAS_HOST" "DEPLOY_TAG=${TAG} bash ${UPDATE_SCRIPT}"
