# Day 1: Terraform Basics — Providers, Resources, State

## Concept

**Infrastructure as Code (IaC)** is the practice of managing infrastructure (servers, networks, databases) through machine-readable definition files, rather than manual processes or interactive configuration tools. Terraform by HashiCorp is the most widely adopted IaC tool — it's cloud-agnostic and uses a declarative language called HCL (HashiCorp Configuration Language).

Three core building blocks:

1. **Providers** — plugins that let Terraform interact with platforms (AWS, Kubernetes, GitHub, even local files). Each provider exposes resources and data sources.
2. **Resources** — the actual infrastructure components you declare: `local_file`, `aws_instance`, `kubernetes_pod`. You describe the desired state, Terraform makes it happen.
3. **State** — a JSON file (`terraform.tfstate`) that maps your config to real-world resources. It's Terraform's source of truth. Without it, Terraform doesn't know what it already manages.

The workflow is always:
```
init → plan → apply → destroy
```

## Task

Do these steps in the `Day-01-Terraform-Basics/` folder.

1. **Install Terraform**  
   - Download from https://developer.hashicorp.com/terraform/install
   - Verify: `terraform --version`

2. **Create `main.tf`** — [`local_file` resource docs](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
   ```hcl
   terraform {
     required_providers {
       local = {
         source = "hashicorp/local"
         version = "2.5.1"
       }
     }
   }

   resource "local_file" "hello" {
     filename = "${path.module}/hello.txt"
     content  = "Hello Terraform"
   }
   ```

3. **Initialize** — `terraform init` — [`terraform init` docs](https://developer.hashicorp.com/terraform/cli/commands/init)
   Observe: downloads the local provider plugin, creates `.terraform.lock.hcl`.

4. **Preview** — `terraform plan` — [`terraform plan` docs](https://developer.hashicorp.com/terraform/cli/commands/plan)
   Observe: shows what will be created (green +). No actual changes yet.

5. **Apply** — `terraform apply --auto-approve` — [`terraform apply` docs](https://developer.hashicorp.com/terraform/cli/commands/apply)
   Observe: creates `hello.txt`. A `terraform.tfstate` file appears.

6. **Inspect state** — `cat terraform.tfstate` — [state docs](https://developer.hashicorp.com/terraform/language/state)
   Notice: it stores the resource type, name, attributes (filename, content), and a unique ID.

7. **Destroy** — `terraform destroy --auto-approve` — [`terraform destroy` docs](https://developer.hashicorp.com/terraform/cli/commands/destroy)
   Observe: removes `hello.txt`. The state file is updated to reflect deletion.

8. **Bonus:** Run `terraform show` after apply — [`terraform show` docs](https://developer.hashicorp.com/terraform/cli/commands/show)

## Real-world relevance

This exact workflow is what you'll use every day as a cloud/platform engineer. Whether you're provisioning an EC2 instance, an S3 bucket, or a Kubernetes cluster, the steps are identical:
- `init` downloads the provider
- `plan` shows you the diff
- `apply` makes it happen
- `destroy` cleans up

The state file is what enables teams to collaborate. It's checked into remote backends (S3, Terraform Cloud) and enables CI/CD pipelines to know what's deployed.

## Summary

- IaC replaces click-ops with declarative config files
- Providers are plugins that bridge Terraform to platforms
- Resources define the desired state of infrastructure
- State is the real-world mapping — Terraform's "source of truth"
- The workflow is always: init → plan → apply → destroy

## Interview Question

Walk me through the Terraform workflow from start to finish. What does each command (`init`, `plan`, `apply`, `destroy`) do? What happens if you delete the state file and run `apply` again? Why is the state file considered critical infrastructure?

Answer to interview question. 
the tf workflow, init-plan-apply-destroy
init-initialize
plan-preview what tf will create
apply-command to let teraform create resource
destroy- command to destroy resources.

If i delete statefile and apply again, tf doesnt know what it manages so tf may recreate duplicate resources. 

state file is critical because it is tf source of truth, it lets terraform knows what it manages