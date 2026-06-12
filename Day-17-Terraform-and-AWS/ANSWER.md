# Day 17 — Model Answer

## How would you provision a VPC with public/private subnets, ALB, and ASG using Terraform?

**Module structure:**
```
networking/
├── main.tf          # VPC module from registry
├── variables.tf
└── outputs.tf       # vpc_id, subnet IDs

compute/
├── main.tf          # ALB + target group + ASG + launch template
├── variables.tf     # vpc_id, subnet_ids
└── outputs.tf       # alb_dns_name
```

**Root main.tf:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "myapp-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

resource "aws_security_group" "web_sg" { ... }
resource "aws_lb" "web_alb" { ... }
resource "aws_autoscaling_group" "web_asg" { ... }
```

## How do you handle secrets in Terraform (RDS passwords)?

- **Never hardcode** secrets in `.tf` files
- Use a **secrets manager**: `data.aws_secretsmanager_secret` or `data.aws_ssm_parameter` (SecureString)
- Use **Terraform Cloud** sensitive variables
- Use environment variables: `TF_VAR_db_password`
- Use `.tfvars` with a placeholder and inject via CI/CD pipeline secrets
- For local dev: prompt interactively or use a vault plugin

## How does the S3 backend prevent concurrent apply corruption?

1. Before each `plan`/`apply`, Terraform writes a lock entry to DynamoDB (LockID = state file path)
2. If another operation tries to acquire the same lock, it waits or fails
3. After completion, the lock entry is deleted
4. S3 versioning provides state history — you can recover a previous version if something goes wrong
