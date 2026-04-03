---
description: Deploy latest code to NAS OpenAlgo container
---

## Quick deploy (develop branch → NAS)

```bash
ssh nas '/volume1/docker/openalgo/repo/deploy/update.sh'
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
ssh nas 'cd /volume1/docker/openalgo/repo && git describe --tags'
```

---

If SSH key auth isn't set up yet, see the manual key setup steps:

```bash
# Generate a dedicated NAS key (no passphrase)
ssh-keygen -t ed25519 -f ~/.ssh/nas_key -N "" -C "openalgo-nas"

# Push the public key to the NAS (password prompt — last time)
cat ~/.ssh/nas_key.pub | ssh thorn@192.168.1.72 \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'

# Add to ~/.ssh/config
echo -e "\nHost nas\n  HostName 192.168.1.72\n  User thorn\n  IdentityFile ~/.ssh/nas_key\n  IdentitiesOnly yes" >> ~/.ssh/config
chmod 600 ~/.ssh/config
```

See `deploy/RELEASE.md` for the full branch and release strategy.
