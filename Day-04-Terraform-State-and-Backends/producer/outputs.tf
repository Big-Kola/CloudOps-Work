output "shared_file_path" {
  value = local_file.shared.filename
}

output "random_id_value" {
  value     = random_id.example.hex
  sensitive = true
}
   