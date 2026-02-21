---
tags: [infrastructure]
---

# <img src="https://github.com/docker.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Docker

Container platform for building, shipping, and running applications in isolated environments.

## Installation

```shell
# OrbStack — fast Docker/Desktop alternative on macOS
brew install --cask orbstack

# Colima + Docker CLI — lightweight local setup
brew install colima docker docker-compose

# Start Colima VM
colima start

# Optional: Docker Desktop
brew install docker docker-compose
```

Or install Docker Desktop (includes a GUI and Kubernetes):

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Docker CLI config (`~/.docker/config.json`)

```json
{
  "auths": {},
  "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
}
```

## Usage

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
