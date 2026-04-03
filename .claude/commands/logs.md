---
description: Stream live logs from NAS OpenAlgo container
---
Stream container logs from the NAS:

```bash
ssh admin@192.168.1.72 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml logs -f openalgo'
```