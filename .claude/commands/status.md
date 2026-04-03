---
description: Check OpenAlgo container status on NAS
---
Check container health and status:

```bash
ssh nas 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml ps'
```