locals {
  is_ovh = var.disk.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  disk = {
    name        = var.disk.name
    size_gb     = var.disk.size_gb
    volume_type = var.disk.ovh.volume_type
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  disk = {
    name                 = var.disk.name
    size_gb              = var.disk.size_gb
    resource_group       = var.disk.azure.resource_group
    location             = var.disk.azure.location
    storage_account_type = var.disk.azure.storage_account_type
    zone                 = var.disk.azure.zone
    tags                 = var.disk.tags
  }
}
