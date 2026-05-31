---
tags: [infrastructure, aws]
---

# <img src="https://github.com/aws.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> EKS

Elastic Kubernetes Service — managed Kubernetes on AWS.

## Installation

```shell
brew install eksctl                             # EKS cluster manager CLI
```

## Cluster Management

```shell
# Create cluster (basic)
eksctl create cluster --name my-cluster --region us-east-1

# Create with nodegroup
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5

# Create with SSH access
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub

# List clusters
eksctl get cluster --region us-east-1

# Delete cluster
eksctl delete cluster --name my-cluster --region us-east-1
```

## Update Kubeconfig

```shell
# Update kubeconfig for cluster
aws eks update-kubeconfig --name my-cluster --region us-east-1

# With aws-vault (for SSO users)
aws-vault exec default -- aws eks update-kubeconfig --name my-cluster --region us-east-1

# With profile
aws eks update-kubeconfig --name my-cluster --region us-east-1 --profile my-profile

# Verify access
kubectl get nodes
kubectl get pods -A
```

## AWS CLI Commands

```shell
# List clusters
aws eks list-clusters --region us-east-1

# Describe cluster
aws eks describe-cluster --name my-cluster --region us-east-1

# Get cluster status
aws eks describe-cluster --name my-cluster --query cluster.status

# Get cluster endpoint
aws eks describe-cluster --name my-cluster --query cluster.endpoint

# Get cluster credentials
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Create nodegroup
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodes \
  --subnets subnet-xxx subnet-yyy \
  --instance-types t3.medium \
  --node-count 2 \
  --region us-east-1

# List nodegroups
aws eks list-nodegroups --cluster-name my-cluster --region us-east-1

# Delete nodegroup
aws eks delete-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodes \
  --region us-east-1
```

## Nodegroups

```shell
# Create nodegroup with eksctl
eksctl create nodegroup \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-ng \
  --node-type t3.medium \
  --nodes 3 \
  --ssh-access

# Scale nodegroup
eksctl scale nodegroup \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-ng \
  --nodes 5

# Drain nodegroup (before deletion)
eksctl drain nodegroup \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-ng

# Delete nodegroup
eksctl delete nodegroup \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-ng
```

## IAM Role for Nodes

```shell
# Create node IAM role
aws iam create-role \
  --role-name eks-node-role \
  --assume-role-policy-document file://node-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Node trust policy (node-trust-policy.json)
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

## Fargate Profiles

```shell
# Create Fargate profile
eksctl create fargateprofile \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-fargate-profile \
  --namespace default

# List Fargate profiles
aws eks list-fargate-profiles --cluster-name my-cluster --region us-east-1

# Delete Fargate profile
eksctl delete fargateprofile \
  --cluster my-cluster \
  --region us-east-1 \
  --name my-fargate-profile
```

## Add-ons

```shell
# List available add-ons
aws eks describe-addon-versions --region us-east-1

# Create add-on (e.g., vpc-cni)
aws eks create-addon \
  --cluster-name my-cluster \
  --addon-name vpc-cni \
  --region us-east-1

# Update add-on
aws eks update-addon \
  --cluster-name my-cluster \
  --addon-name vpc-cni \
  --addon-version latest \
  --region us-east-1

# List add-ons
aws eks list-addons --cluster-name my-cluster --region us-east-1

# Delete add-on
aws eks delete-addon \
  --cluster-name my-cluster \
  --addon-name vpc-cni \
  --region us-east-1
```

## OIDC Provider

```shell
# Create OIDC provider for service accounts
eksctl create iamidentitymapping \
  --cluster my-cluster \
  --region us-east-1 \
  --arn arn:aws:iam::123456789:role/MyRole \
  --username my-service-account \
  --group system:authenticated

# List IAM mappings
aws iam list-open-id-connect-providers

# Get OIDC provider ARN
aws eks describe-cluster \
  --name my-cluster \
  --query cluster.identity.oidc.issuer \
  --region us-east-1
```

## Troubleshooting

```shell
# Check cluster connectivity
kubectl cluster-info

# Get node status
kubectl get nodes -o wide

# Check pod status
kubectl get pods -A -o wide

# Describe nodes
kubectl describe nodes

# Check events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Logs from node
kubectl debug node/my-node -it --image=busybox -- crictl logs

# Check CoreDNS
kubectl logs -n kube-system deployment/coredns
```

## Useful Tools

```shell
# Install kubectl
brew install kubectl

# Install awscli
brew install awscli

# Update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Verify cluster
kubectl get svc
```

## References

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [eksctl](https://eksctl.io/)
- [EKS kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)