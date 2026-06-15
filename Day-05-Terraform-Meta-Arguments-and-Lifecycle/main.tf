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

resource "local_file" "numbered" {
  count    = 3
  filename = "${path.module}/node-${count.index}.txt"
  content  = "Node number ${count.index}"
}

resource "local_file" "protected" {
  filename = "${path.module}/critical.txt"
  content  = "DO NOT DELETE"

  lifecycle {
    prevent_destroy = true
  }
}

resource "local_file" "ignore_perms" {
  filename        = "${path.module}/ignored.txt"
  content         = "Permissions will be ignored"
  file_permission = "0777"

  lifecycle {
    ignore_changes = [
      file_permission,
    ]
  }
}

resource "local_file" "depends_demo" {
  filename = "${path.module}/after-everything.txt"
  content  = "I run last"

  depends_on = [
    local_file.protected,
    local_file.configs,
  ]
}