locals {
  is_ovh = var.container_registry.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id = var.container_registry.ovh.project_id

  container_registry = {
    deploy = var.container_registry.deploy
    name   = var.container_registry.name
    region = var.container_registry.ovh.region
  }

  registry_users  = var.registry_users
  ip_restrictions = var.ip_restrictions
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  container_registry = {
    deploy         = var.container_registry.deploy
    name           = var.container_registry.name
    location       = var.container_registry.azure.location
    resource_group = var.container_registry.azure.resource_group
    sku            = var.container_registry.azure.sku
    tags           = var.container_registry.tags
  }

  registry_users  = var.registry_users
  ip_restrictions = var.ip_restrictions
}
