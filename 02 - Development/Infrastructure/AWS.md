---
tags: [infrastructure]
---

# <img src="https://github.com/aws.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> AWS

Amazon Web Services — cloud infrastructure platform.

## Installation

```shell
brew install awscli                          # Official AWS CLI v2
pip3 install aws-mfa                         # MFA helper for assuming roles
brew install 99designs/tap/aws-vault         # Secure credential storage
```

## Credentials

### Option 1: AWS Console → Access Keys

1. Open [IAM Console](https://console.aws.amazon.com/iam/) → Users → Select your user
2. **Security credentials** tab → **Create access key**
3. Copy the **Access key ID** and **Secret access key**
4. Configure locally:

```shell
aws configure
# Enter Access Key ID
# Enter Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### Option 2: AWS Console → Command Line Access (Recommended for SSO)

1. Open [IAM Identity Center](https://console.aws.amazon.com/iamidentity/) (or your SSO URL)
2. Select your user → **Command line or programmatic access**
3. Copy the export commands or use the AWS CLI browser extension
4. Or configure SSO:

```shell
aws configure sso
# SSO start URL: https://your-org.awsapps.com/start
# SSO region: us-east-1
# Default region: us-east-1
```

### Option 3: IAM Role → MFA Session

```shell
# Get MFA serial from console (IAM → Users → Security credentials → MFA device)
export AWS_MFA_DEVICE=arn:aws:iam::123456789:mfa/your-username

# Assume role with MFA code
aws sts assume-role \
  --role-arn arn:aws:iam::123456789:role/YourRole \
  --serial-number $AWS_MFA_DEVICE \
  --token-code 123456

# Or use aws-mfa
aws-mfa --duration 43200
```

### Credential Files

- Credentials: `~/.aws/credentials`
- Config: `~/.aws/config`
- Using aws-vault:

```shell
aws-vault add default          # Add credentials interactively
aws-vault exec default -- aws sts get-caller-identity
aws-vault exec default -- zsh  # Open shell with temp credentials
```

## Common Commands

```shell
# Identity and region
aws sts get-caller-identity
aws configure get region

# S3
aws s3 ls
aws s3 cp file.txt s3://bucket/path/
aws s3 sync ./local/ s3://bucket/

# EC2
aws ec2 describe-instances
aws ec2 start-instances --instance-ids i-xxxxx
aws ec2 stop-instances --instance-ids i-xxxxx

# Lambda
aws lambda list-functions
aws lambda invoke --function-name my-func out.json

# ECR (container registry)
aws ecr get-login-password | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
```

## EKS

Managed Kubernetes on AWS. See [[EKS]] for detailed commands (eksctl, nodegroups, Fargate, add-ons).

## ECS

Elastic Container Service — managed container orchestration.

### ECS CLI Installation

```shell
brew install amazon-ecs-cli
```

### Basic ECS Commands

```shell
# List clusters
aws ecs list-clusters

# List services
aws ecs list-services --cluster my-cluster

# List tasks
aws ecs list-tasks --cluster my-cluster --service-name my-service

# Describe task
aws ecs describe-tasks --cluster my-cluster --tasks task-arn

# Get logs
aws logs tail /ecs/my-cluster --follow
```

### ECS Exec (run commands in containers)

```shell
# Enable ECS Exec in task definition first
aws ecs execute-command \
  --cluster my-cluster \
  --task task-id \
  --container my-container \
  --interactive \
  --command "/bin/sh"
```

### Connect to ECR

```shell
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t my-app .
docker tag my-app:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## Key Services

| Service            | Description                                |
| ------------------ | ------------------------------------------ |
| **EC2**            | Virtual compute instances                  |
| **S3**             | Object storage                             |
| **Lambda**         | Serverless functions                       |
| **RDS**            | Managed relational databases               |
| **DynamoDB**       | Managed NoSQL database                     |
| **EKS**            | Managed Kubernetes                         |
| **ECS**            | Managed container orchestration            |
| **Cognito**        | User authentication                        |
| **CloudFormation** | Infrastructure as code (cf. [[Terraform]]) |
| **CloudWatch**     | Monitoring and observability               |
| **API Gateway**    | Managed API hosting                        |
| **SNS**            | Pub/sub messaging                          |
| **Kinesis**        | Real-time data streaming                   |
| **Step Functions** | Serverless workflow orchestration          |
| **ECR**            | Container registry                         |

## References

- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [aws-mfa on GitHub](https://github.com/broamski/aws-mfa)
- [aws-vault on GitHub](https://github.com/99designs/aws-vault)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)