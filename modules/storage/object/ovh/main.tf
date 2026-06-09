# https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_storage

resource "ovh_cloud_project_storage" "storage" {
  service_name = var.ovh_project_id
  region_name  = var.region
  name         = var.name

  encryption = {
    sse_algorithm = var.encryption_sse
  }

  versioning = {
    status = var.versioning
  }

  object_lock = var.object_lock_days > 0 ? {
    status = "enabled"
    rule = {
      mode   = "governance"
      period = "P${var.object_lock_days}D"
    }
  } : null
}
