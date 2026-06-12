# Day 2: Variables, Data Sources, Outputs

## Concept

Hardcoding values is the fastest way to create brittle, unreusable configs. Terraform provides three mechanisms to make configs flexible and composable:

1. **Input Variables** — parameters you pass in. Support types (`string`, `number`, `bool`, `list`, `map`, `object`), default values, validation blocks, and sensitive flags.
2. **Local Values** — like variables but evaluated within the module. Use `locals { ... }` to avoid repeating expressions.
3. **Data Sources** — read information from existing infrastructure (or local state) that Terraform didn't create. Queried at plan time.
4. **Outputs** — expose values from a module or root config. Useful for passing data between modules or to CI/CD.

## Task

Start from Day 1's config and refactor it.

1. **Create `variables.tf`**
   ```hcl
   variable "file_name" {
     description = "Path to the file"
     type        = string
     default     = "${path.module}/hello.txt"
   }

   variable "file_content" {
     description = "Content to write"
     type        = string

     validation {
       condition     = length(var.file_content) > 0
       error_message = "File content must not be empty."
     }
   }

   variable "file_permission" {
     description = "File permission octal"
     type        = string
     default     = "0644"
   }
   ```

2. **Update `main.tf`** to use the variables
   ```hcl
   resource "local_file" "hello" {
     filename    = var.file_name
     content     = var.file_content
     file_permission = var.file_permission
   }
   ```

3. **Create `outputs.tf`**
   ```hcl
   output "file_path" {
     value       = local_file.hello.filename
     description = "Path to the created file"
   }

   output "file_content" {
     value     = local_file.hello.content
     sensitive = true
   }
   ```

4. **Use a data source** to read the file back
   ```hcl
   data "local_file" "read_hello" {
     filename = var.file_name
   }

   output "read_content" {
     value = data.local_file.read_hello.content
   }
   ```

5. **Create `terraform.tfvars`** with actual values
   ```hcl
   file_name    = "greeting.txt"
   file_content = "Hello from variables!"
   ```

6. **Run** `terraform init`, `terraform plan`, `terraform apply --auto-approve`

7. **Override with CLI** — `terraform apply -var="file_content=CLI override" --auto-approve`

8. **Try an invalid value** — set `file_content = ""` in `terraform.tfvars` and run `plan`. Observe the validation error.

## Real-world relevance

In real projects, variables are how you separate config from logic. You have one module but use different `.tfvars` files for dev, staging, and prod. Data sources let you discover existing VPCs, AMIs, or secrets without hardcoding IDs. Outputs feed into downstream systems — a CI/CD pipeline that needs the IP of a new load balancer, for example.

## Summary

- Variables make configs reusable across environments
- Validation blocks catch bad input at plan time
- Data sources read existing infrastructure (even resources Terraform didn't create)
- Outputs expose values for other modules, CI/CD, or humans
- `.tfvars` files separate configuration from code

## Interview Question

What's the difference between a variable, a local value, and a data source? When would you use each? How does variable precedence work (where can a variable be set, and which takes priority)?
