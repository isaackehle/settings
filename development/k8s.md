# Kubernetes

```bash
brew install kubernetes-cli
brew install kubectx
brew install derailed/k9s/k9s
```

- To test and view contexts run

```bash
kubectl config get-clusters
```

- The output should look like

```bash
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/prd-internal
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/test
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/devtest
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/prd-external
```
