# Both providers are declared here so Terraform knows their schemas.
# Only the provider matching cloud_provider needs to be configured by the caller —
# the other will be initialized but makes no API calls (count = 0 resources).
terraform {
  required_version = ">= 1.5"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
