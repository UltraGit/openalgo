---
description: Stream live logs from NAS OpenAlgo container
---
Stream container logs from the NAS:

```bash
ssh nas 'docker compose -f /volume1/docker/openalgo/repo/docker-compose.nas.yml logs -f openalgo'
```