resource "local_file" "this" {
  filename        = var.filename
  content         = var.content
  file_permission = var.file_permission
}