---
tags: [infrastructure, kubernetes]
---

# <img src="https://github.com/rancher.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Rancher CLI

Command-line interface for managing Rancher resources and Kubernetes clusters.

## Installation

```shell
brew install rancher-cli
```

## Configuration

```shell
# Login to Rancher server
rancher login https://<rancher-server> --token <token>

# Or login interactively
rancher login https://<rancher-server>
```

## Start / Usage

```shell
# List clusters
rancher cluster list

# Switch context
rancher cluster switch <cluster-name>

# List projects
rancher project list

# Manage namespaces
rancher namespace list

# Run kubectl commands directly
rancher kubectl get pods -n <namespace>
```

## References

- [Rancher CLI Documentation](https://rancher.com/docs/rancher/v2.x/en/cli/)
- [GitHub](https://github.com/rancher/cli)