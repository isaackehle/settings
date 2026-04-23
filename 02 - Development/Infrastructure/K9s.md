---
tags: [infrastructure]
---

# <img src="https://github.com/derailed/k9s.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> K9s

Terminal UI for Kubernetes cluster management.

## Installation

```shell
brew install derailed/k9s/k9s                       # Terminal UI for Kubernetes
```

## Launch

```shell
# Launch K9s
k9s

# Launch with specific context
k9s --context my-cluster

# Launch with specific namespace
k9s --namespace my-namespace
```

## Keybindings

| Key        | Action                              |
| ---------- | ----------------------------------- |
| `?`        | Show keybindings help               |
| `q` / `Esc`| Quit                                |
| `l`        | View logs (pod view)                |
| `d`        | Describe resource                   |
| `e`        | Edit resource in editor             |
| `s`        | Scale resource                      |
| `Shift-d`  | Delete resource                     |
| `y`        | Show resource YAML                  |
| `Ctrl-a`   | Show resource-wide actions          |
| `p` / `P`  | Sort ascending / descending         |
| `/`        | Filter by text                     |
| `c`        | Show resource config                |
| `n`        | Create new resource                 |
| `Shift-s`  | Shell into container                |

## Views

| View    | Command     | Description              |
| ------- | ----------- | ------------------------ |
| Pods    | `po`        | List all pods            |
| Deployments | `deploy` | List deployments        |
| Services | `svc`      | List services            |
| Ingress  | `ing`      | List ingresses           |
| ConfigMaps | `cm`      | List configmaps          |
| Secrets  | `sec`      | List secrets             |
| Nodes    | `no`        | List cluster nodes        |
| PVs      | `pv`        | List persistent volumes  |
| Helm    | `helm`      | List Helm releases        |

## Contexts and Namespaces

```shell
# In K9s:
# :ctx         → Switch context
# :ctxs        → List all contexts
# :ns          → Switch namespace
# :ns default  → Switch to default namespace
```

## Troubleshooting

```shell
# Tail logs
# In pod view: press l to tail logs

# Describe
# In any view: press d to describe

# Shell into container
# In pod view: Shift-s

# Port-forward (via kubectl)
kubectl port-forward svc/my-svc 8080:80
```

## Configuration

```shell
# Config file location
~/.config/k9s/config.yaml

# Example config:
# k9s:
#   ui:
#     port: 30000
#   kubeConfig: ~/.kube/config
#   namespace: default
#   hide:
#     - nodes
#   command:
#     cold:
#       wait: 5
#       attempts: 5
```

## References

- [K9s Documentation](https://k9scli.io/)
- [K9s GitHub](https://github.com/derailed/k9s)