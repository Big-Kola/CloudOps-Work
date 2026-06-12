module "hello_en" {
  source   = "./modules/file_writer"
  filename = "greeting_en.txt"
  content  = "Hello"
}

module "hello_fr" {
  source   = "./modules/file_writer"
  filename = "greeting_fr.txt"
  content  = "Bonjour"
}

output "en_file" {
  value = module.hello_en.file_path
}

output "fr_file" {
  value = module.hello_fr.file_path
}