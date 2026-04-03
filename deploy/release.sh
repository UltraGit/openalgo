#!/bin/bash
# ============================================================================
# OpenAlgo NAS — Release Tagging Script
# ============================================================================
# Run from WSL on the develop branch when you're ready to cut a NAS release.
#
# Usage:
#   ./deploy/release.sh <version>    e.g.  ./deploy/release.sh 0.1
#
# Creates and pushes tag:  nas/v<version>
# Tags must be cut from the 'develop' branch.
# The tag is what deploy/update.sh uses when DEPLOY_TAG is set.
#
# Full release workflow:
#   1. Merge your feature branch into develop
#   2. Run smoke tests:  ./deploy/smoke-test.sh abce
#   3. Cut the release:  ./deploy/release.sh 0.1
#   4. Deploy to NAS:    ./deploy/deploy-tag.sh nas/v0.1
#
# See deploy/RELEASE.md for the complete procedure.
# ============================================================================

set -euo pipefail

VERSION="${1:?Usage: ./deploy/release.sh <version>   e.g. 0.1}"
TAG="nas/v${VERSION}"
REQUIRED_BRANCH="develop"

# ---- preflight checks -------------------------------------------------------

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$REQUIRED_BRANCH" ]; then
    echo "ERROR: releases must be cut from '$REQUIRED_BRANCH' (currently on '$CURRENT_BRANCH')"
    echo "  git checkout develop && git merge feature/your-branch"
    exit 1
fi

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "ERROR: uncommitted changes present — commit or stash before releasing"
    git status --short
    exit 1
fi

if git tag -l | grep -qx "$TAG"; then
    echo "ERROR: tag '$TAG' already exists"
    echo "  Existing nas/ tags:"
    git tag -l 'nas/*' | sort -V | sed 's/^/    /'
    exit 1
fi

# ---- confirm ----------------------------------------------------------------

COMMIT_SHORT=$(git rev-parse --short HEAD)
COMMIT_FULL=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=format:"%s")

echo "=== OpenAlgo NAS Release ==="
echo ""
echo "  Tag:     $TAG"
echo "  Branch:  $REQUIRED_BRANCH"
echo "  Commit:  $COMMIT_SHORT  ($COMMIT_MSG)"
echo ""
echo "  Existing nas/ tags:"
git tag -l 'nas/*' | sort -V | sed 's/^/    /' || echo "    (none yet)"
echo ""
read -rp "Create and push $TAG → $COMMIT_SHORT? [y/N] " yn
if [[ ! "${yn,,}" =~ ^y ]]; then
    echo "Aborted — no tag created."
    exit 0
fi

# ---- tag and push -----------------------------------------------------------

git tag -a "$TAG" -m "NAS release $TAG

Branch:  $REQUIRED_BRANCH
Commit:  $COMMIT_FULL
"

git push origin "$TAG"

# ---- post-release instructions ----------------------------------------------

echo ""
echo "Released: $TAG → $COMMIT_SHORT"
echo ""
echo "Deploy to NAS now:"
echo ""
echo "  ./deploy/deploy-tag.sh $TAG"
echo ""
echo "Or manually:"
echo ""
echo "  ssh admin@192.168.1.72 \\"
echo "    'DEPLOY_TAG=$TAG /volume1/docker/openalgo/repo/deploy/update.sh'"
