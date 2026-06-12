# Day 17: Terraform + AWS

## Concept

This is where Terraform meets AWS in practice. Instead of clicking around the AWS console or running `aws-cli` commands, you declare your entire infrastructure as code. Today you'll provision real AWS resources using Terraform — the same way you did with the `local` provider on Day 1.

The core idea: Terraform is cloud-agnostic, but the **AWS provider** gives you resources for every AWS service (`aws_instance`, `aws_s3_bucket`, `aws_vpc`, `aws_db_instance`, etc.).

You'll need:
- AWS credentials configured (`~/.aws/credentials` or env vars)
- An S3 bucket for remote state (optional for today, but you should set it up)

## Task

1. **Configure AWS provider** — `provider.tf` — [AWS provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs), [S3 backend docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
     backend "s3" {
       bucket         = "your-tf-state-bucket"
       key            = "day17/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "terraform-locks"
       encrypt        = true
     }
   }

   provider "aws" {
     region = "us-east-1"
   }
   ```

2. **Create an S3 bucket for state** (via CLI once, then Terraform will use it) — [state locking docs](https://developer.hashicorp.com/terraform/language/state/locking)
   ```bash
   aws s3 mb s3://your-tf-state-bucket
   aws s3api put-bucket-versioning \
     --bucket your-tf-state-bucket \
     --versioning-configuration Status=Enabled

   # Create DynamoDB table for locking
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. **Create a VPC module from registry** — `main.tf` — [AWS VPC module docs](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "5.8.1"

     name = "day17-vpc"
     cidr = "10.0.0.0/16"

     azs             = ["us-east-1a", "us-east-1b"]
     private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
     public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

     enable_nat_gateway = true
     enable_vpn_gateway = false

     tags = {
       Terraform = "true"
       Environment = "day17"
     }
   }
   ```

4. **Add a security group** — [`aws_security_group` resource docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
   ```hcl
   resource "aws_security_group" "web_sg" {
     name   = "day17-web-sg"
     vpc_id = module.vpc.vpc_id

     ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }

     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }

     tags = {
       Name = "day17-web-sg"
     }
   }
   ```

5. **Launch an EC2 instance with user data** — [`aws_instance` resource docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance), [`data.aws_ami` docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
   ```hcl
   data "aws_ami" "amazon_linux_2" {
     most_recent = true
     owners      = ["amazon"]

     filter {
       name   = "name"
       values = ["amzn2-ami-hvm-*-x86_64-gp2"]
     }
   }

   resource "aws_instance" "web" {
     ami                    = data.aws_ami.amazon_linux_2.id
     instance_type          = "t3.micro"
     subnet_id              = module.vpc.public_subnets[0]
     vpc_security_group_ids = [aws_security_group.web_sg.id]
     associate_public_ip_address = true

     user_data = <<-EOF
       #!/bin/bash
       yum update -y
       yum install -y httpd
       systemctl start httpd
       systemctl enable httpd
       echo "<h1>Provisioned by Terraform</h1>" > /var/www/html/index.html
     EOF

     tags = {
       Name = "day17-web"
     }
   }

   output "web_public_ip" {
     value = aws_instance.web.public_ip
   }
   ```

6. **Create `variables.tf`** to make env reusable — [input variable docs](https://developer.hashicorp.com/terraform/language/values/variables)
   ```hcl
   variable "environment" {
     description = "Environment name"
     type        = string
     default     = "dev"
   }

   variable "instance_type" {
     description = "EC2 instance type"
     type        = string
     default     = "t3.micro"
   }
   ```

7. **Run**
   ```bash
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

8. **Verify** — curl the public IP from the output
   ```bash
   curl http://$(terraform output -raw web_public_ip)
   ```

9. **Destroy**
   ```bash
   terraform destroy --auto-approve
   ```

## Real-world relevance

This is exactly what real teams do: use Terraform modules (official or internal) to compose infrastructure, manage state remotely with locking, and treat infrastructure as code with reviewable PRs. The VPC module alone replaces dozens of aws-cli commands.

## Summary

- Terraform + AWS provider provisions real cloud resources
- Use modules from the Registry instead of writing everything from scratch
- Remote state (S3 + DynamoDB) enables team collaboration
- User data bootstraps EC2 instances
- Always `terraform destroy` to avoid ongoing costs

## Interview Question

How would you provision a VPC with public and private subnets, an ALB, and an ASG using Terraform? Walk through the module structure. How do you handle secrets in Terraform (e.g., RDS passwords)? How does the S3 backend prevent concurrent apply operations from corrupting state?
