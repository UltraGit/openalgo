# NAS Release Management

## Branch and Tag Strategy

```
upstream/main
      │
      ▼
    main          ← upstream OpenAlgo tracking only; never deployed to NAS
      │
      ▼
  develop         ← your active NAS work; NAS dev deploys pull from here
      │
      ├── feature/nas-deployment   ← WIP feature branches; merge → develop when ready
      ├── feature/kraken-broker
      └── ...
      │
      ▼ (when stable)
  nas/v0.1        ← immutable release tag; what the NAS runs in production
  nas/v0.2
  ...
```

### Branch roles

| Branch / Tag | Purpose | Who deploys it |
|---|---|---|
| `main` | Upstream OpenAlgo (clean fork tracking) | Nobody — NAS never runs this |
| `develop` | Your integrated NAS additions | NAS dev deploys (fast-moving) |
| `feature/*` | Work in progress | Local only |
| `nas/vX.Y` | Immutable production releases | NAS via `deploy-tag.sh` |

---

## Day-to-Day Development Flow

```
feature/* → develop → [smoke test] → nas/vX.Y tag → NAS deploy
```

### 1. Work on a feature branch

```bash
git checkout develop
git checkout -b feature/my-feature
# ... make changes, commit ...
```

### 2. Merge to develop when ready

```bash
git checkout develop
git merge --no-ff feature/my-feature
git push origin develop
```

### 3. Deploy develop to NAS for testing (no tag needed)

```bash
# From WSL — NAS pulls latest develop
ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'
# (DEPLOY_BRANCH defaults to 'develop' in update.sh)
```

Or with the smoke test first:

```bash
./deploy/smoke-test.sh abce     # pre-flight: vol, port, env, websocket
ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'
```

---

## Cutting a Release

Run these steps from WSL on a clean `develop` branch.

### Step 1 — Confirm develop is clean and pushed

```bash
git checkout develop
git status          # must be clean
git push origin develop
```

### Step 2 — Run smoke tests against the NAS

```bash
./deploy/smoke-test.sh abce
```

All components should PASS before tagging.

### Step 3 — Cut the release tag

```bash
./deploy/release.sh 0.1
```

This will:
- Check you are on `develop` with a clean working tree
- Show you the commit being tagged and any existing `nas/` tags
- Prompt for confirmation
- Create annotated tag `nas/v0.1` and push it to origin

### Step 4 — Deploy the tag to the NAS

```bash
./deploy/deploy-tag.sh nas/v0.1
```

This SSHs to the NAS and runs `update.sh` with `DEPLOY_TAG=nas/v0.1`. The NAS will:
1. `git fetch --tags` to get the new tag
2. `git checkout --detach nas/v0.1` (detached HEAD — reproducible)
3. Rebuild and restart the Docker container

### Step 5 — Verify

```bash
# Tail logs directly
ssh admin@192.168.1.72 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml logs -f openalgo'

# Check status
ssh admin@192.168.1.72 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml ps'

# Confirm the tag the NAS is running
ssh admin@192.168.1.72 'cd /volume1/docker/openalgo/repo && git describe --tags'
```

---

## Rolling Back

To roll back to a previous tag:

```bash
./deploy/deploy-tag.sh nas/v0.1    # redeploy any earlier tag
```

To see all available tags:

```bash
git tag -l 'nas/*' | sort -V
```

---

## Pulling Upstream OpenAlgo Changes into develop

When upstream releases a new version and you want to merge it:

```bash
git checkout main
git pull upstream main        # requires: git remote add upstream https://github.com/marketcalls/openalgo
git push origin main

git checkout develop
git merge --no-ff main
# resolve any conflicts with your NAS additions
git push origin develop
```

Then follow the release procedure above to cut a new `nas/vX.Y` tag.

---

## Environment Variables for update.sh

`deploy/update.sh` respects two environment variables:

| Variable | Default | Description |
|---|---|---|
| `DEPLOY_TAG` | *(unset)* | If set, checks out this exact tag (e.g. `nas/v0.1`). Takes priority over `DEPLOY_BRANCH`. |
| `DEPLOY_BRANCH` | `develop` | Branch to pull if no tag is specified. |

Examples:

```bash
# Deploy latest develop (default)
ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'

# Deploy a specific release tag
ssh admin@192.168.1.72 \
  'DEPLOY_TAG=nas/v0.2 /volume1/docker/openalgo/repo/deploy/update.sh'

# Deploy a feature branch for one-off testing (not recommended for production)
ssh admin@192.168.1.72 \
  'DEPLOY_BRANCH=feature/kraken-broker /volume1/docker/openalgo/repo/deploy/update.sh'
```

---

## On Option 4: Docker Image Releases

This project currently uses Option 2 (git tags). Option 4 (Docker image tags via a
registry) becomes worth implementing when:

- A CI/CD pipeline (GitHub Actions) is set up to build images on push
- You need multi-architecture support (NAS ARM64 + WSL x86_64)
- You want zero-git on the NAS (pull image only, no repo required)

At that point, the flow would be:
1. GitHub Actions builds and pushes `ghcr.io/user/openalgo:nas-v0.3` on tag push
2. NAS runs `docker pull ghcr.io/user/openalgo:nas-v0.3 && docker compose up -d`
3. No `git` commands needed on the NAS at all

The `nas/vX.Y` tag convention used here is forward-compatible with that model.
