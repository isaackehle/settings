---
tags: [infrastructure]
---

# <img src="https://github.com/hashicorp.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Terraform

Infrastructure as code tool for provisioning and managing cloud resources declaratively.

## Installation

```shell
brew install terraform                          # Official Terraform CLI
brew install tfswitch                          # Switch between Terraform versions
```

## Configuration

```shell
# Format terraform files
terraform fmt

# Validate configuration
terraform validate

# Show terraform version
terraform version
```

## Core Commands

```shell
# Initialize working directory (downloads providers, modules)
terraform init

# Initialize with backend config
terraform init -backend-config="bucket=my-bucket"

# Preview changes (what will be created/modified/destroyed)
terraform plan
terraform plan -out=tfplan                     # Save plan to file
terraform plan -var-file=prod.tfvars           # With variable file

# Apply changes
terraform apply
terraform apply tfplan                         # Apply saved plan
terraform apply -auto-approve                  # Skip approval prompt

# Destroy resources
terraform destroy
terraform destroy -target=aws_instance.my_ec2 # Destroy specific resource
terraform destroy -var-file=prod.tfvars        # With variable file
```

## State Management

```shell
# Show current state
terraform show

# List resources in state
terraform state list

# Show resource details
terraform state show aws_instance.my_ec2

# Move resource (rename or move in state)
terraform state mv aws_instance.old aws_instance.new

# Pull remote state (for debugging)
terraform state pull > terraform.tfstate

# Push state (rarely needed)
terraform state push terraform.tfstate

# Remove resource from state (doesn't destroy infrastructure)
terraform state rm aws_instance.my_ec2
```

## Workspaces

```shell
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new prod

# Switch workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace (must be empty)
terraform workspace delete dev
```

## Variables and Outputs

```shell
# Plan with variable values
terraform plan -var="region=us-west-2"
terraform plan -var-file=dev.tfvars

# Apply with variables
terraform apply -var="instance_type=t3.medium"

# List outputs
terraform output
terraform output s3_bucket_name               # Specific output

# Refresh outputs from state
terraform output -state=terraform.tfstate

# Sensitive outputs (masked)
terraform output -raw db_password
```

## Import Existing Resources

```shell
# Import existing AWS EC2 into state
terraform import aws_instance.my_ec2 i-xxxxxxx

# Import into new resource
terraform import 'aws_instance.new[0]' i-xxxxxxx

# Preview import (dry run)
terraform plan -generate-config-out=generated.tf
```

## Providers

```shell
# Initialize provider plugins
terraform init

# Upgrade providers to latest compatible version
terraform init -upgrade

# Pin provider version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Modules

```shell
# Call module in configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Get module (download to .terraform/modules)
terraform get
terraform get -update                           # Update modules
```

## Debugging and Troubleshooting

```shell
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Enable structured logging
export TF_LOG=JSON
terraform apply 2>&1 | jq

# Graph resource dependencies
terraform graph | dot -Tpng > graph.png

# Console (evaluate expressions)
terraform console
> var.region
> length(module.vpc.public_subnets)
```

## Common Workflow

```shell
# Fresh start for new environment
terraform init -backend=false
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars -auto-approve

# Lockfile management
terraform lockfile -upgrade                      # Upgrade providers in lockfile

# Verify state
terraform validate
terraform fmt
terraform plan
```

## tfvars Files

```shell
# Variable file naming convention
dev.tfvars        # Development
prod.tfvars       # Production
staging.tfvars    # Staging

# Auto-load (terraform.auto.tfvars)
# Files named terraform.tfvars or *.auto.tfvars are auto-loaded

# Specify var file explicitly
terraform apply -var-file=prod.tfvars
```

## References

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [tfsec (security scanning)](https://aquasecurity.github.io/tfsec/)