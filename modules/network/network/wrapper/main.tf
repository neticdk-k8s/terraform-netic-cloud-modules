locals {
  is_ovh = var.network.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id = var.network.ovh.project_id

  network = {
    name    = var.network.name
    vlan_id = var.network.ovh.vlan_id
    regions = var.network.ovh.regions
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  network = {
    name                = var.network.name
    location            = var.network.azure.location
    resource_group      = var.network.azure.resource_group
    address_space       = var.network.azure.address_space
    subnets             = var.network.azure.subnets
    create_default_nsgs = var.network.azure.create_default_nsgs
    tags                = var.network.tags
  }
}
