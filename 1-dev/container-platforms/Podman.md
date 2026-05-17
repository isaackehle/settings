---
tags: [infrastructure]
---

# <img src="https://github.com/containers.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Podman

Docker-compatible container runtime without a daemon. Preferred over Docker Desktop for macOS.

## Installation

```shell
brew install podman
```

## Configuration

```shell
# Initialize Podman (creates the VM)
podman machine init
podman machine start
```

### Docker Compatibility

Use `docker` commands with Podman by setting the socket and aliasing:

```shell
command -v podman >/dev/null 2>&1 || return 0
export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')"
alias docker=podman
```

Add this to your shell profile (e.g., `~/.profile.d/_podman`) to enable Docker CLI compatibility.

## Start / Usage

```shell
# Run a container
podman run -it ubuntu bash

# List running containers
podman ps

# Stop a container
podman stop <container-id>

# Build an image
podman build -t my-image .
```

### Podman Machine (macOS)

```shell
# Check machine status
podman machine list

# Start/stop machine
podman machine start
podman machine stop

# Reset machine (if issues)
podman machine reset
```

### Podman Compose

```shell
brew install podman-compose
```

```shell
# Run docker-compose.yml files
podman-compose up -d
```

### Prisma (for LiteLLM database)

```shell
pip install prisma
```

### pyenv (for Python version management)

```shell
# Install pyenv if not already installed
brew install pyenv

# Add to shell profile (if not already configured)
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Install a Python version
pyenv install 3.11
pyenv install 3.12
```

## References

- [Podman](https://podman.io/)
- [Podman Desktop](https://podman-desktop.io/)