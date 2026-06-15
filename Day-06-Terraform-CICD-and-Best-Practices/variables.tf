variable "file_name" {
  description = "Name of the file to create"
  type        = string
  default     = "hello.txt"
}

variable "file_content" {
  description = "Content of the file"
  type        = string
  default     = "Hello Terraform"
}
