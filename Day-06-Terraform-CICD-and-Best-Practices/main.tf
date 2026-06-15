terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/${var.file_name}"
  content  = var.file_content
}