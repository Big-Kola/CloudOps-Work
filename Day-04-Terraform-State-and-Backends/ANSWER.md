# Day 4 — Model Answer

## How does Terraform state locking work?

State locking prevents two concurrent operations from modifying the same state file simultaneously. When a backend supports locking (e.g., S3 + DynamoDB, Terraform Cloud):

1. Before running `plan` or `apply`, Terraform acquires a lock
2. The lock is released when the operation completes
3. If a lock is already held, the second operation waits (configurable timeout) or fails

## Why is it important?

Without locking, two engineers (or a CI pipeline and an engineer) running `apply` at the same time can corrupt the state file. The last write wins, potentially losing resource mappings and causing drift.

## Walk me through S3 + DynamoDB setup:

1. **Create an S3 bucket** with versioning enabled (for state recovery)
2. **Create a DynamoDB table** with `LockID` (string) as the primary key, using pay-per-request billing
3. **Configure the backend**:
```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## What happens if someone runs `apply` while a lock is held?

The second `apply` will wait (default timeout ~10 minutes for S3/DynamoDB). If the lock isn't released in time, it errors: `Acquiring state lock. Lock Info: ...`. This prevents concurrent state corruption. The lock is released when the first `apply` completes (success or failure).
