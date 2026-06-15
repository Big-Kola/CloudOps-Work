output "file_path" {
  value = local_file.hello.filename
}

output "file_content" {
  value = local_file.hello.content
}
