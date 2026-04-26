---
tags: [infrastructure]
---

# <img src="https://github.com/helm.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Helm

Kubernetes package manager for templating and managing manifests.

## Installation

```shell
brew install helm                                # Kubernetes package manager
```

## Core Commands

```shell
# Search for charts
helm search hub <package>                       # Search Helm Hub
helm search repo <package>                      # Search added repos

# Install a chart
helm install <release-name> <chart> -n <namespace> --create-namespace

# List installed releases
helm list -A                                   # All namespaces

# Upgrade release
helm upgrade <release-name> <chart>

# Rollback
helm rollback <release-name>                   # Rollback to previous
helm rollback <release-name> 1                 # Rollback to revision 1

# Show values (configurable options)
helm show values <chart>

# Install with custom values
helm install <release> <chart> -f values.yaml
helm install <release> <chart> --set key=value
```

## Chart Management

```shell
# Create new chart
helm create my-chart

# Lint chart (validate)
helm lint ./my-chart

# Package chart
helm package ./my-chart

# Dependency update
helm dependency update ./my-chart

# List dependencies
helm dependency list ./my-chart
```

## Values and Configuration

```shell
# Show all values
helm get values <release>

# Show all values (including defaults)
helm get values <release> --all

# Show full rendered manifest
helm template <release> <chart>

# Install with --dry-run (local render, no cluster needed)
helm install <release> <chart> --dry-run --debug

# Get full values with explanation
helm show values <chart> --all > values-full.yaml

# Diff values before upgrade
helm diff values <release> values.yaml
```

## Release Management

```shell
# Uninstall release
helm uninstall <release>

# List all releases with status
helm list --all

# Get release history
helm history <release>

# Pause/unpause release
helm pause <release>
helm unpause <release>

# Add repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repos
helm repo update

# List repos
helm repo list

# Remove repo
helm repo remove bitnami
```

## Testing and Debugging

```shell
# Debug templates (local render)
helm template <release> <chart> --debug

# Test release
helm test <release>

# Pull chart (download)
helm pull bitnami/nginx

# Inspect chart (show chart info)
helm inspect all bitnami/nginx

# Verify chart
helm verify ./nginx-*.tgz
```

## Repository Examples

```shell
# Add common repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts

# Update
helm repo update

# Search nginx
helm search repo nginx
```

## Chart Structure

```text
my-chart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default values
├── templates/          # Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── _helpers.tpl    # Named templates
├── Chart.lock          # Locked dependencies
└── charts/              # Embedded dependencies
```

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Hub](https://hub.helm.sh/)
- [Artifact Hub](https://artifacthub.io/)