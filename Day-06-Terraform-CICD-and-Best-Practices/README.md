# Day 6: Terraform CI/CD & Best Practices

## Concept

Terraform in production means automation, collaboration, and guardrails. Key practices:

- **Formatting** — `terraform fmt -recursive` enforces consistent HCL style
- **Validation** — `terraform validate` checks syntax and internal consistency
- **Locking** — `terraform plan` and `apply` acquire a state lock so only one pipeline runs at a time
- **Plan output as comment** — CI posts the plan diff on PRs for human review
- **Apply only from main** — manual or auto-approve after PR merge
- **Policy as Code** — Sentinel (HashiCorp) or OPA/Conftest to enforce rules (e.g., "no public S3 buckets")

## Task

1. **Create a proper Terraform project structure**
   ```
   Day-06-Terraform-CICD-and-Best-Practices/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── terraform.tfvars.example
   └── Makefile
   ```

2. **`main.tf`** — simple local_file config (like Day 1/2)

3. **`terraform.tfvars.example`**
   ```hcl
   file_name    = "config.txt"
   file_content = "your-content-here"
   ```

4. **`Makefile`**
   ```makefile
   .PHONY: fmt validate plan apply destroy clean

   fmt:
   	terraform fmt -recursive

   validate:
   	terraform init
   	terraform validate

   plan: validate
   	terraform plan

   apply: validate
   	terraform plan -out=tfplan
   	terraform apply tfplan

   destroy:
   	terraform destroy

   clean:
   	rm -rf .terraform terraform.tfstate* *.txt
   ```

5. **Create `.github/workflows/terraform.yml`**
   ```yaml
   name: Terraform CI

   on:
     pull_request:
       paths: ["**/*.tf", "**/*.tfvars"]

   jobs:
     check:
       runs-on: ubuntu-latest
       defaults:
         run:
           working-directory: Day-06-Terraform-CICD-and-Best-Practices

       steps:
         - uses: actions/checkout@v4

         - uses: hashicorp/setup-terraform@v3
           with:
             terraform_version: 1.9.0

         - name: Format
           run: terraform fmt -check -recursive

         - name: Init
           run: terraform init

         - name: Validate
           run: terraform validate

         - name: Plan
           run: terraform plan
   ```

6. **Push this to your GitHub repo** and open a PR (even to yourself) to see the workflow run

7. **Add `terraform.tfvars` to `.gitignore`**
   ```
   terraform.tfvars
   *.tfstate
   *.tfstate.backup
   .terraform/
   ```

## Real-world relevance

Every Terraform pipeline I've seen in production follows this pattern:
1. PR opened → `terraform fmt -check` + `terraform validate` + `terraform plan`
2. Plan is posted as a PR comment
3. Team reviews the diff
4. PR merged to main → `terraform apply` runs automatically (or with manual approval)
5. State stored in S3 with DynamoDB locking

Without this pipeline, teams apply changes blindly and step on each other.

## Summary

- Always run `fmt -check` and `validate` in CI
- Plan output should be visible on PRs for human review
- Never store `.tfvars` with secrets in git — use CI secrets or Vault
- Lock state so concurrent pipelines don't conflict
- Use policy tools (Sentinel/OPA) for compliance guardrails

## Interview Question

How would you design a CI/CD pipeline for Terraform in a team of 10 engineers? Walk through the PR workflow, what checks run, who approves, and how `apply` is triggered. How do you handle secrets in Terraform CI/CD?
