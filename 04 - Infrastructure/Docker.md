---
tags: [infrastructure]
---

# Container Platforms

Tools for containerizing applications and managing containerized environments.

## <img src="https://github.com/docker.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Docker Desktop

Official Docker GUI application for macOS with Kubernetes support.

```shell
brew install --cask docker
```

```shell
# Start Docker Desktop from Applications
open -a Docker
```

## <img src="https://github.com/docker.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Docker CLI

Command-line interface for Docker container management.

```shell
brew install docker docker-compose
```

### Docker CLI config (`~/.docker/config.json`)

```json
{
  "auths": {},
  "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
}
```

```shell
# Run a container
docker run -it ubuntu bash

# List running containers
docker ps

# Stop a container
docker stop <container-id>

# Build an image
docker build -t my-image .
```

## <img src="https://github.com/abiosoft.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OrbStack

Fast Docker Desktop alternative optimized for macOS.

```shell
brew install --cask orbstack
```

```shell
# Start OrbStack from Applications
open -a OrbStack
```

## <img src="https://github.com/abiosoft.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Colima

Lightweight container runtime using Lima for macOS.

```shell
brew install colima docker docker-compose
```

```shell
# Start Colima VM
colima start
```

## PostgreSQL via Docker

```shell
brew install postgresql@15
createuser -s postgres
```

Example: spin up a local Postgres instance with a schema:

```shell
#!/usr/bin/env bash
set -euo pipefail

mkdir -p $HOME/docker/volumes/postgres
docker run --rm --name pg-docker \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=dev \
  -d -p 5432:5432 \
  -v $HOME/docker/volumes/postgres:/var/lib/postgresql \
  postgres

sleep 3
export PGPASSWORD=postgres
psql -U postgres -d dev -h localhost -f schema.sql
psql -U postgres -d dev -h localhost -f data.sql
```

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
