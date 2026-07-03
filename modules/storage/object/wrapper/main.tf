locals {
  is_ovh = var.storage.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id = var.storage.ovh.project_id

  storage = {
    name             = var.storage.name
    region           = var.storage.ovh.region
    versioning       = var.storage.ovh.versioning
    encryption_sse   = var.storage.ovh.encryption_sse
    object_lock_days = var.storage.ovh.object_lock_days
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  storage = {
    name             = var.storage.name
    resource_group   = var.storage.azure.resource_group
    location         = var.storage.azure.location
    replication_type = var.storage.azure.replication_type
    versioning       = var.storage.azure.versioning
    retention_days   = var.storage.azure.retention_days
    container_name   = var.storage.azure.container_name
    tags             = var.storage.tags
  }
}
