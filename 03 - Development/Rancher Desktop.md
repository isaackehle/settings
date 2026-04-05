---
tags: [development, kubernetes, containers]
---

# <img src="https://github.com/rancherfederal.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Rancher Desktop

Container and Kubernetes management for Mac, Windows, and Linux desktops.

## Installation

### macOS

```shell
# Using Homebrew
brew install rancher

# Or download from website
# https://rancherdesktop.io/
```

### Windows

Download the installer from: https://rancherdesktop.io/

### Linux

```bash
# Using package managers
# Ubuntu/Debian
curl -s https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | gpg --dearmor | sudo dd status=none of=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./' | sudo dd status=none of=/etc/apt/sources.list.d/isv-rancher-stable.list
sudo apt update
sudo apt install rancher-desktop

# Or download .deb/.rpm from website
```

## Configuration

After installation, Rancher Desktop provides:

- **Container Runtime**: Choose between containerd or Docker
- **Kubernetes Version**: Select your preferred Kubernetes version
- **Port Forwarding**: Automatic port forwarding for services
- **Images**: Built-in image management

### Basic Setup

1. Launch Rancher Desktop
2. Choose container runtime (containerd recommended for Kubernetes)
3. Enable Kubernetes
4. Configure resource limits (CPU, Memory)

## Usage

```bash
# Check status
kubectl cluster-info

# View nodes
kubectl get nodes

# Deploy applications
kubectl apply -f deployment.yaml

# Access Kubernetes dashboard
kubectl proxy
# Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Features

- **Kubernetes Cluster**: Local Kubernetes cluster for development
- **Container Management**: Docker-compatible container runtime
- **Traefik Ingress**: Built-in ingress controller
- **Port Forwarding**: Automatic port mapping
- **Images**: Pull and manage container images
- **Extensions**: Support for Kubernetes extensions

## Troubleshooting

### Common Issues

**Port conflicts**: If ports 80/443 are in use, configure custom ports in settings.

**Resource limits**: Increase memory allocation if containers fail to start.

**Network issues**: Check firewall settings for Kubernetes networking.

## References

- [Rancher Desktop Documentation](https://docs.rancherdesktop.io/)
- [Rancher Desktop GitHub](https://github.com/rancher-sandbox/rancher-desktop)
- [Getting Started with Kubernetes](https://kubernetes.io/docs/getting-started-guides/)