# Day 1 — Model Answer

## Walk me through the Terraform workflow from start to finish.

**`terraform init`**
- Downloads provider plugins and modules specified in the config
- Configures the backend for state storage (local or remote)
- Idempotent — safe to run multiple times
- Creates `.terraform.lock.hcl` to lock provider versions

**`terraform plan`**
- Reads the current state and config, computes a diff
- Shows what will be created (+), changed (~), or destroyed (-)
- No side effects — a dry run
- Output can be saved with `-out=tfplan` for later apply

**`terraform apply`**
- Executes the planned changes against real infrastructure
- Updates `terraform.tfstate` with the new resource metadata
- With `--auto-approve`, skips the confirmation prompt

**`terraform destroy`**
- An `apply` that generates a plan to remove all tracked resources
- Updates state to reflect nothing managed

## What happens if you delete the state file and run `apply` again?

Terraform has no memory of existing resources. It will try to create everything from scratch. The original resources still exist in the cloud but are orphaned (unmanaged). This can cause:
- Duplicate resources (name conflicts, e.g., two S3 buckets with the same name)
- Resource leaks (unused instances, volumes, load balancers — costing money)
- Corruption if a partially overlapping state is restored

## Why is the state file considered critical infrastructure?

- Maps logical resource names to real-world IDs (e.g., `aws_instance.web` → `i-0abcd1234`)
- Stores resource dependencies so Terraform knows the correct create/update/destroy order
- Enables team collaboration through remote backends (S3) with locking (DynamoDB)
- Contains metadata (attributes, outputs) that `plan` needs for accurate diffs
- May contain sensitive data (plaintext passwords, keys) — must be encrypted at rest and access-controlled with IAM
