terraform {
  required_version = ">= 1.0"
  backend "local" {
    path = "producer.tfstate"
  }
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}
