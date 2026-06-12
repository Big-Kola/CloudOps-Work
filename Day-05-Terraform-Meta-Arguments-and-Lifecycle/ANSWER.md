# Day 5 — Model Answer

## Compare `count` and `for_each`.

| Feature | `count` | `for_each` |
|---------|---------|------------|
| Input type | number | map or set(string) |
| Access index | `count.index` | `each.key` / `each.value` |
| Resource address | `resource.name[0]`, `[1]`, etc. | `resource.name["key"]` |
| Ref removal behavior | Index shift | Removed by key, others unaffected |

## When would you use `for_each` over `count`?

Use `for_each` when:
- Items are defined in a map (natural keyed access)
- Items may be added or removed in the middle — `count` causes index shifting, which can destroy and recreate resources unexpectedly
- Each instance needs a stable, meaningful address (e.g., `aws_instance.web["api"]`)

Use `count` when:
- You need N identical resources (e.g., 3 nearly identical subnets)
- You're creating a fixed number of items from a numeric condition

## The index-shift problem with `count`:

If you have `count = 3` (indices 0, 1, 2) and remove the first item from the list, the remaining items shift: what was index 1 becomes 0, and what was 2 becomes 1. Terraform sees this as "destroy old [0], modify old [1]→[0], modify old [2]→[1]" — potentially recreating or modifying resources unintentionally. `for_each` avoids this because items are keyed, not indexed.

## `create_before_destroy` vs `prevent_destroy`:

- **`create_before_destroy`** — when a resource must be updated in-place but the provider forces replacement, Terraform creates the replacement first, then removes the old one. Used for zero-downtime deployments (load balancers, databases).
- **`prevent_destroy`** — a safety guard that causes `terraform destroy` (or an `apply` that would delete the resource) to fail with an error. Used for production databases, S3 buckets with critical data, or IAM roles.
