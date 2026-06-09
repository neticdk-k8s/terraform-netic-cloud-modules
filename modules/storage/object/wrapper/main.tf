module "ovh" {
  count  = var.cloud_provider == "ovh" ? 1 : 0
  source = "../ovh"

  ovh_project_id   = var.ovh.project_id
  name             = var.name
  region           = var.ovh.region
  versioning       = var.ovh.versioning
  encryption_sse   = var.ovh.encryption_sse
  object_lock_days = var.ovh.object_lock_days
}

module "azure" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "../azure"

  name             = var.name
  resource_group   = var.azure.resource_group
  location         = var.azure.location
  replication_type = var.azure.replication_type
  versioning       = var.azure.versioning
  retention_days   = var.azure.retention_days
  container_name   = var.azure.container_name
}
