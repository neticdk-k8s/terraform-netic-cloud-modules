terraform {
  required_version = ">= 1.5"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}
