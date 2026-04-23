---
tags: [infrastructure]
---

# <img src="https://github.com/kubernetes.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Kubernetes

Container orchestration system for automating deployment, scaling, and management of containerized applications.

## Installation

```shell
brew install kubernetes-cli     # Official Kubernetes CLI
brew install kubectl            # kubectl (already in kubernetes-cli, included for completeness)
brew install kubectx            # Kubernetes context switcher (also adds kubens)
brew install minikube           # Local Kubernetes cluster for local development
brew install derailed/k9s/k9s   # Terminal UI for cluster management
brew install helm               # Kubernetes package manager
```

## Configuration

```shell
# List configured clusters
kubectl config get-clusters

# List all contexts
kubectl config get-contexts

# Show current context
kubectl config current-context

# Switch cluster context
kubectx <cluster-name>

# Set default namespace
kubectl config set-context --current --namespace=<namespace>
```

## Common Commands

```shell
# Get resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl get all -n <namespace>

# Describe resources (troubleshooting)
kubectl describe pod <pod-name>
kubectl describe deployment <deploy-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>              # tail
kubectl logs <pod-name> -c <container>  # specific container

# Execute into pod
kubectl exec -it <pod-name> -- sh

# Port forwarding
kubectl port-forward <pod-name> 8080:80

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# Scale deployment
kubectl scale deployment/<name> --replicas=3

# Apply/delete manifests
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml
kubectl apply -f <directory>/

# Watch resources
kubectl get pods -w

# Explain resource types
kubectl explain pod
```

## Helm

Package manager for Kubernetes. See [[Helm]] for detailed commands and chart management.

## K9s

Terminal UI for Kubernetes. See [[K9s]] for keybindings and detailed usage.

## Local Development

```shell
# Start minikube cluster
minikube start
minikube start --driver=docker
minikube start --memory=4g --cpus=2

# Access dashboard
minikube dashboard

# Get minikube IP
minikube ip

# Tunnel for LoadBalancer services
minikube tunnel

# Stop/delete cluster
minikube stop
minikube delete
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm](https://helm.sh/)
- [K9s](https://k9scli.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)