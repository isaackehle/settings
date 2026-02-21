---
tags: [infrastructure]
---

# AWS

Amazon Web Services — cloud infrastructure platform.

## Installation

```shell
# AWS CLI v2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# MFA helper
pip3 install aws-mfa

# Secure credential storage
brew install 99designs/tap/aws-vault
```

## Configuration

```shell
aws configure
```

Credentials are stored in `~/.aws/credentials` and config in `~/.aws/config`.

## Key Services

| Service | Description |
|---|---|
| **EC2** | Virtual compute instances |
| **S3** | Object storage |
| **Lambda** | Serverless functions |
| **RDS** | Managed relational databases |
| **DynamoDB** | Managed NoSQL database |
| **EKS** | Managed Kubernetes |
| **Cognito** | User authentication |
| **CloudFormation** | Infrastructure as code (cf. [[Terraform]]) |
| **CloudWatch** | Monitoring and observability |
| **API Gateway** | Managed API hosting |
| **SNS** | Pub/sub messaging |
| **Kinesis** | Real-time data streaming |
| **Step Functions** | Serverless workflow orchestration |
| **Corretto** | Amazon's OpenJDK distribution |

## References

- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [aws-mfa on GitHub](https://github.com/broamski/aws-mfa)
- [aws-vault on GitHub](https://github.com/99designs/aws-vault)
