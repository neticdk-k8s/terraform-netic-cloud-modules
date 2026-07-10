locals {
  is_ovh = var.gateway.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  gateway = {
    name         = var.gateway.name
    service_name = var.gateway.ovh.project_id
    region       = var.gateway.region
    model        = var.gateway.ovh.model
    subnet_ids   = var.gateway.subnet_ids
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  gateway = {
    name                    = var.gateway.name
    location                = var.gateway.region
    resource_group          = var.gateway.azure.resource_group
    public_ip_id            = var.gateway.azure.public_ip_id
    subnet_ids              = var.gateway.subnet_ids
    idle_timeout_in_minutes = var.gateway.azure.idle_timeout_in_minutes
    tags                    = var.gateway.tags
  }
}
