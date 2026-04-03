---
description: Deploy latest code to NAS OpenAlgo container
---
Run the NAS deployment update script via SSH:

```bash
ssh admin@192.168.1.72 '/volume1/docker/openalgo/repo/deploy/update.sh'
```

If SSH key auth isn't set up yet, run this from WSL first:

```bash
ssh-copy-id admin@192.168.1.72
```

The update script will:
1. Pull the latest code from GitHub (main branch)
2. Rebuild the Docker image
3. Restart the container
4. Tail logs so you can confirm a healthy startup