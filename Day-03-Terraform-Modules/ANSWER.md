# Day 3 — Model Answer

## How would you structure Terraform code for a team managing 3 microservices that share a VPC and a database?

```
infrastructure/
├── modules/
│   ├── vpc/                    # VPC + subnets + route tables
│   ├── database/               # RDS instance + security group
│   └── service/                # ALB + ASG + security group
├── envs/
│   ├── dev/
│   │   ├── main.tf             # calls vpc, database, service modules
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── .github/workflows/terraform.yml
```

The root config in each env folder:
1. Calls the `vpc` module once
2. Calls the `database` module once
3. Calls the `service` module three times (once per microservice), passing `vpc_id` and `db_endpoint` as inputs

## How do you version and distribute shared modules?

- Store modules in a dedicated Git repository (e.g., `git@github.com:company/terraform-modules.git`)
- Tag releases with semantic versions: `v1.0.0`, `v1.1.0`
- Reference by Git URL with version: `source = "git::https://github.com/company/terraform-modules.git//vpc?ref=v1.0.0"`
- Or publish to a private Terraform Registry
- Use version constraints in the calling config (`version = "~> 1.0"`) to control updates
