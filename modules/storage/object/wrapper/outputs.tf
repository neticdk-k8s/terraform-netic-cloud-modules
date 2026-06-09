output "storage_id" {
  description = "ID of the created object storage resource"
  value       = var.cloud_provider == "ovh" ? module.ovh[0].storage_id : module.azure[0].storage_id
}

output "storage_name" {
  description = "Name of the created object storage resource"
  value       = var.cloud_provider == "ovh" ? module.ovh[0].storage_name : module.azure[0].storage_name
}

output "storage_region" {
  description = "Region of the created object storage resource"
  value       = var.cloud_provider == "ovh" ? module.ovh[0].storage_region : module.azure[0].storage_region
}

output "connection_string" {
  description = "Connection string (null for OVH)"
  value       = var.cloud_provider == "ovh" ? module.ovh[0].connection_string : module.azure[0].connection_string
  sensitive   = true
}
