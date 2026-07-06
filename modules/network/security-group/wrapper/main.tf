locals {
  is_ovh = var.security_group.ovh != null
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  security_group = {
    name           = var.security_group.name
    location       = var.security_group.azure.location
    resource_group = var.security_group.azure.resource_group
    tags           = var.security_group.tags
    rules          = var.security_group.rules
  }
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  security_group = {
    name  = var.security_group.name
    tags  = var.security_group.tags
    rules = var.security_group.rules
  }
}
