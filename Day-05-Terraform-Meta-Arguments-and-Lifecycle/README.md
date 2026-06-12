# Day 5: Meta-arguments & Lifecycle Rules

## Concept

Meta-arguments are special arguments available on every resource that change how Terraform behaves:

1. **`count`** — create N instances of a resource from a number. Accessed as `count.index`.
2. **`for_each`** — create instances from a map or set of strings. Accessed as `each.key` and `each.value`.
3. **`depends_on`** — explicit dependency when Terraform can't infer ordering.
4. **`provider`** — specify a non-default provider alias.

**Lifecycle rules** control how Terraform creates, updates, and deletes resources:
- `create_before_destroy` — create replacement before removing old (zero-downtime updates)
- `prevent_destroy` — protection against accidental deletion (plan/apply will reject)
- `ignore_changes` — ignore specific attribute changes (useful for metadata that external systems modify)

## Task

1. **Create `main.tf` with `for_each`** — [`for_each` docs](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
   ```hcl
   variable "files" {
     description = "Map of filename to content"
     type        = map(string)
     default = {
       "app.conf"   = "APP_ENV=production"
       "db.conf"    = "DB_HOST=localhost"
       "cache.conf" = "CACHE_TTL=3600"
     }
   }

   resource "local_file" "configs" {
     for_each = var.files
     filename = "${path.module}/${each.key}"
     content  = each.value
   }
   ```

2. **Add `count` example** — [`count` docs](https://developer.hashicorp.com/terraform/language/meta-arguments/count)
   ```hcl
   resource "local_file" "numbered" {
     count    = 3
     filename = "${path.module}/node-${count.index}.txt"
     content  = "Node number ${count.index}"
   }
   ```

3. **Add `lifecycle` rules** — [`lifecycle` docs](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
   ```hcl
   resource "local_file" "protected" {
     filename = "${path.module}/critical.txt"
     content  = "DO NOT DELETE"

     lifecycle {
       prevent_destroy = true
     }
   }

   resource "local_file" "ignore_perms" {
     filename    = "${path.module}/ignored.txt"
     content     = "Permissions will be ignored"
     file_permission = "0644"

     lifecycle {
       ignore_changes = [
         file_permission,
       ]
     }
   }
   ```

4. **Add explicit `depends_on`** — [`depends_on` docs](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on)
   ```hcl
   resource "local_file" "depends_demo" {
     filename = "${path.module}/after-everything.txt"
     content  = "I run last"

     depends_on = [
       local_file.protected,
       local_file.configs,
     ]
   }
   ```

5. **Run** `terraform init && terraform plan && terraform apply --auto-approve`

6. **Test `prevent_destroy`** — run `terraform destroy`. Observe the error on `protected`.

7. **Test `ignore_changes`** — manually change `ignored.txt` permissions to `0777`, then run `terraform plan`. Terraform won't try to fix it.

## Real-world relevance

- `for_each` replaces copy-paste resource definitions entirely. One module, many instances.
- `create_before_destroy` is essential for load balancers, databases, and any resource where downtime isn't acceptable.
- `prevent_destroy` is used for production databases, S3 buckets with critical data, or IAM roles.
- `ignore_changes` handles situations where Kubernetes or an external controller modifies tags/annotations on resources Terraform manages.

## Summary

- `count` and `for_each` create multiple resource instances
- `depends_on` fixes implicit dependency gaps
- `create_before_destroy` enables zero-downtime updates
- `prevent_destroy` is a safety net for critical resources
- `ignore_changes` stops Terraform from fighting external changes

## Interview Question

Compare `count` and `for_each`. When would you use `for_each` over `count`? What happens to resource addressing when you remove an item from the middle of a `count` list (the index-shift problem)? How does `create_before_destroy` differ from `prevent_destroy`?
