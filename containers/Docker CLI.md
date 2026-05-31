---
tags: [infrastructure]
---

# <img src="https://github.com/docker.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Docker CLI

Command-line interface for Docker container management.

## Installation

```shell
brew install docker docker-compose
```

## Configuration

```json
{
  "auths": {},
  "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
}
```

## Start / Usage

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

## References

- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)