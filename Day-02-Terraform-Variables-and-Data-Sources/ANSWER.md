# Day 2 — Model Answer

## What's the difference between a variable, a local value, and a data source?

**Input Variable** — a parameter passed into a module (or root config). Used to make configs reusable across environments. Set via `.tfvars` files, CLI `-var`, environment variables `TF_VAR_`, or default values.

**Local Value** — an expression assigned to a name within a module using `locals { ... }`. Evaluated lazily. Used to avoid repeating complex expressions. Not settable from outside the module.

**Data Source** — queries existing infrastructure (that Terraform may or may not have created). Read at plan time. Example: looking up the latest AMI ID, reading an existing VPC, or fetching a remote state's outputs.

## When would you use each?

- **Variables** — when you need to pass different values per environment (dev/staging/prod) or per module call
- **Locals** — when you have repeated expressions inside a module (e.g., `"${var.env}-${var.name}"` used in multiple places)
- **Data Sources** — when you need to discover information about existing infrastructure (e.g., "what's the default VPC ID?", "what's the latest Ubuntu AMI?")

## How does variable precedence work?

From lowest to highest priority:

1. Default value in `variable` block
2. `*.auto.tfvars` files (alphabetical order)
3. `terraform.tfvars` file
4. `-var-file` flag (last one wins)
5. Environment variables (`TF_VAR_*`)
6. CLI flag `-var` (highest priority)

If a variable has no default and no value is provided, Terraform prompts interactively.
