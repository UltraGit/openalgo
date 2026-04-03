---
description: Check OpenAlgo container status on NAS
---
Check container health and status:

```bash
ssh admin@192.168.1.72 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml ps'
```