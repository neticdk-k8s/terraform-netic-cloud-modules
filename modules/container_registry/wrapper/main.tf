module "ovh" {
  count  = var.cloud_provider == "ovh" ? 1 : 0
  source = "../ovh"

  ovh_project_id = try(var.ovh_config.project_id, "")

  container_registry = {
    deploy = var.container_registry.deploy
    name   = var.container_registry.name
    region = try(var.ovh_config.region, "")
  }

  registry_users  = var.registry_users
  ip_restrictions = var.ip_restrictions
}

module "azure" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "../azure"

  container_registry = {
    deploy         = var.container_registry.deploy
    name           = var.container_registry.name
    location       = try(var.azure_config.location, "")
    resource_group = try(var.azure_config.resource_group, "")
    sku            = try(var.azure_config.sku, "Basic")
  }

  registry_users  = var.registry_users
  ip_restrictions = var.ip_restrictions
}
