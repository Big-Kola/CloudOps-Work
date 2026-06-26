output "consumed_from_producer" {
  value = data.terraform_remote_state.producer.outputs.shared_file_path
}