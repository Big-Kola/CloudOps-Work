terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

resource "local_file" "hello" {
  filename        = var.file_name
  content         = var.file_content
  file_permission = var.file_permission
}

data "local_file" "read_hello" {
  filename = var.file_name
}

   