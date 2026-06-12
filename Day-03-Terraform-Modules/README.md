# Day 3: Terraform Modules

## Concept

A **module** is a self-contained package of Terraform configs that's treated as a single unit. Every Terraform config is a module — the root module. Child modules are called from the root to compose infrastructure from reusable building blocks.

Modules have:
- **Input variables** — what you pass in
- **Output values** — what you get back
- **Resources/data sources** — what the module manages
- **Local values** — internal helpers

Modules are versioned and can come from the local filesystem, the Terraform Registry, or Git/HTTP sources.

## Task

1. **Create the module structure** — [module docs](https://developer.hashicorp.com/terraform/language/modules)
   ```
   modules/
     file_writer/
       main.tf
       variables.tf
       outputs.tf
   ```

2. **`modules/file_writer/variables.tf`** — [input variable docs](https://developer.hashicorp.com/terraform/language/values/variables)
   ```hcl
   variable "filename" {
     description = "Path to the output file"
     type        = string
   }

   variable "content" {
     description = "Content to write"
     type        = string
   }

   variable "file_permission" {
     description = "File permission octal"
     type        = string
     default     = "0644"
   }
   ```

3. **`modules/file_writer/main.tf`** — [`local_file` resource docs](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
   ```hcl
   resource "local_file" "this" {
     filename    = var.filename
     content     = var.content
     file_permission = var.file_permission
   }
   ```

4. **`modules/file_writer/outputs.tf`** — [output value docs](https://developer.hashicorp.com/terraform/language/values/outputs)
   ```hcl
   output "file_path" {
     value       = local_file.this.filename
     description = "Path to the created file"
   }
   ```

5. **Root `main.tf`** — call the module twice — [calling module docs](https://developer.hashicorp.com/terraform/language/modules/syntax)
   ```hcl
   module "hello_en" {
     source   = "./modules/file_writer"
     filename = "greeting_en.txt"
     content  = "Hello"
   }

   module "hello_fr" {
     source   = "./modules/file_writer"
     filename = "greeting_fr.txt"
     content  = "Bonjour"
   }

   output "en_file" {
     value = module.hello_en.file_path
   }

   output "fr_file" {
     value = module.hello_fr.file_path
   }
   ```

6. **Run** `terraform init` (detects module source), `terraform plan`, `terraform apply --auto-approve`

7. **Examine** — `terraform output` shows the file paths from both module calls

## Real-world relevance

Modules are the backbone of production Terraform usage. You never write raw resources for common patterns. Instead:
- Use the official AWS VPC module instead of writing VPC + subnets + route tables manually
- Create an internal "app-service" module that encapsulates EC2/ASG/ALB/security groups
- Version modules with Git tags so teams pin to known-working versions

## Summary

- A module is any directory with Terraform files — you're already using modules
- Child modules are called with `module "name" { source = "..." }`
- Modules hide complexity and enforce consistency
- Sources: local path, Registry, GitHub, S3, HTTP
- Always version your modules (Git tags, registry versions)

## Interview Question

How would you structure Terraform code for a team managing 3 microservices that share a VPC and a database? Walk me through the module hierarchy. How do you version and distribute shared modules across teams?
