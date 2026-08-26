terraform {
  required_version = ">= 1.5"
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
