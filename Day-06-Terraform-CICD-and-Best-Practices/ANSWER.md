# Day 6 — Model Answer

## How would you design a CI/CD pipeline for Terraform in a team of 10 engineers?

**PR Workflow:**

1. Developer creates a branch, modifies `.tf` files, opens a PR
2. GitHub Action runs on PR:
   - `terraform fmt -check -recursive` — enforces code style
   - `terraform init` + `terraform validate` — checks syntax
   - `terraform plan` — generates the diff, posted as a PR comment via a bot
3. Team members review the plan output in the PR
4. Senior engineer or platform team approves
5. PR merged to `main` branch
6. Separate GitHub Action on `main`:
   - Runs `terraform apply` with auto-approve (or manual approval gate)
   - State stored in S3 with DynamoDB locking

**Secrets handling:**
- Never commit `.tfvars` with secrets to Git
- Use CI secrets (GitHub Actions secrets, GitLab CI variables) injected as `TF_VAR_*` environment variables
- For teams: use Vault, AWS Secrets Manager, or Terraform Cloud's sensitive variable support
- Rotate access keys regularly and use IAM roles for CI runners where possible
