variable "filename" {
  description = "Path to the output file"
  type        = string
}

variable "content" {
  description = "Content to write"
  type        = string
}

variable "file_permission" {
  description = "File permission octal"
  type        = string
  default     = "0644"
}