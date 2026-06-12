# Day 4: Remote State & Backends

## Concept

By default, Terraform stores state as a local `terraform.tfstate` file. This breaks in a team — if two people run `apply`, they overwrite each other's state and corrupt it. **Backends** configure where state is stored and how it's locked.

A **backend** determines:
- Where state is stored (local disk, S3, GCS, Azure Storage, Terraform Cloud)
- Whether state locking is supported (prevents concurrent operations)
- Whether state encryption is used at rest

The **`terraform_remote_state`** data source lets one config read another config's outputs from its state file — enabling cross-stack dependencies without coupling the code.

## Task

1. **Create two separate configs** to demonstrate cross-stack state sharing.

   **Config A (state-producer) — `Day-04-Terraform-State-and-Backends/producer/`**
   ```hcl
   # versions.tf
   terraform {
     required_version = ">= 1.0"
     backend "local" {
       path = "producer.tfstate"
     }
   }

   # main.tf
   resource "local_file" "shared" {
     filename = "${path.module}/shared-config.txt"
     content  = "This is shared state data"
   }

   # outputs.tf
   output "shared_file_path" {
     value = local_file.shared.filename
   }
   ```

   **Config B (state-consumer) — `Day-04-Terraform-State-and-Backends/consumer/`**
   ```hcl
   # versions.tf
   terraform {
     required_version = ">= 1.0"
     backend "local" {
       path = "consumer.tfstate"
     }
   }

   # main.tf
   data "terraform_remote_state" "producer" {
     backend = "local"
     config = {
       path = "../producer/producer.tfstate"
     }
   }

   resource "local_file" "from_state" {
     filename = "${path.module}/consumed-output.txt"
     content  = "Read from producer: ${data.terraform_remote_state.producer.outputs.shared_file_path}"
   }

   # outputs.tf
   output "consumed_from_producer" {
     value = data.terraform_remote_state.producer.outputs.shared_file_path
   }
   ```

2. **Apply producer first**: `cd producer && terraform init && terraform apply --auto-approve`

3. **Apply consumer**: `cd consumer && terraform init && terraform apply --auto-approve`

4. **Verify** — Check `consumed-output.txt` — it contains the path from the producer's state.

5. **Add a `random` resource** to the producer to simulate a generated secret. Mark the output as `sensitive = true`. See what happens in the consumer.

## Real-world relevance

In real AWS usage, you configure:
```hcl
backend "s3" {
  bucket         = "my-company-terraform-state"
  key            = "prod/network/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-locks"
  encrypt        = true
}
```

This enables: team collaboration (state locking with DynamoDB), disaster recovery (state in S3), and audit trails. You then use `terraform_remote_state` to share a VPC ID from a network stack to an app stack without duplicating code.

## Summary

- Local state doesn't work for teams — you need a remote backend
- State locking prevents concurrent operations from corrupting state
- `terraform_remote_state` reads outputs from another config's state
- Common backends: S3 (with DynamoDB locking), Terraform Cloud, GCS, AzureRM
- State contains sensitive data — encrypt it and control access with IAM

## Interview Question

How does Terraform state locking work? Why is it important? Walk me through setting up S3 as a backend with DynamoDB locking. What happens if someone runs `apply` while a lock is held?
