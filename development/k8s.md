# Kubernetes

```shell
brew install kubernetes-cli
brew install kubectx
brew install minikube
brew install derailed/k9s/k9s
```

- To test and view contexts run

```shell
kubectl config get-clusters
```

- The output should look like

```shell
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/prd-internal
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/test
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/devtest
arn:aws:eks:us-east-1:IDIDIDIDIDID:cluster/prd-external
```

## K9s

- brew install derailed/k9s/k9s
- [Install (k9scli.io)](https://k9scli.io/topics/install/)
