---
tags: [infrastructure]
---

# Kubernetes

Container orchestration system for automating deployment, scaling, and management of containerized applications.

## Installation

```shell
brew install kubernetes-cli kubectx minikube
brew install derailed/k9s/k9s
```

## Usage

```shell
# List configured clusters
kubectl config get-clusters

# Switch cluster context
kubectx <cluster-name>

# Get pods in a namespace
kubectl get pods -n my-namespace

# Apply a manifest
kubectl apply -f deployment.yaml
```

### K9s

Terminal UI for Kubernetes cluster management.

```shell
brew install derailed/k9s/k9s
```

Launch with:

```shell
k9s
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K9s](https://k9scli.io/)
- [Helm — Kubernetes package manager](https://helm.sh/)
