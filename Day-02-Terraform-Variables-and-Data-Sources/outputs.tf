output "file_path" {
  value       = local_file.hello.filename
  description = "Path to the created file"
}

output "file_content" {
  value     = local_file.hello.content
  sensitive = true
}

output "read_content" {
  value = data.local_file.read_hello.content
}