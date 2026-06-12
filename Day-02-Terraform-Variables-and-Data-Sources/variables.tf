variable "file_name" {
  description = "Path to the file"
  type        = string
}

variable "file_content" {
  description = "Content to write"
  type        = string

  validation {
    condition     = length(var.file_content) > 0
    error_message = "File content must not be empty."
  }
}

variable "file_permission" {
  description = "File permission octal"
  type        = string
  default     = "0644"
}