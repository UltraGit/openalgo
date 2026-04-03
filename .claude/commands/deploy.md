---
description: Deploy latest code to NAS OpenAlgo container
---

## Quick deploy (develop branch → NAS)

```bash
ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'
```

## Deploy a specific release tag

```bash
./deploy/deploy-tag.sh nas/v0.1
```

## Cut a new release tag (from develop, after smoke tests pass)

```bash
./deploy/smoke-test.sh abce          # pre-flight checks
./deploy/release.sh 0.2              # creates and pushes nas/v0.2
./deploy/deploy-tag.sh nas/v0.2      # deploys to NAS
```

## List available release tags

```bash
git tag -l 'nas/*' | sort -V
```

## Check what the NAS is currently running

```bash
ssh admin@192.168.1.72 'cd /volume1/docker/openalgo/repo && git describe --tags'
```

---

If SSH key auth isn't set up yet, run from WSL first:

```bash
ssh-copy-id admin@192.168.1.72
```

See `deploy/RELEASE.md` for the full branch and release strategy.
