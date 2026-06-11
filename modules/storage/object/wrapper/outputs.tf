output "storage_id" {
  description = "ID of the created object storage resource"
  value       = local.is_ovh ? one(module.ovh[*].storage_id) : one(module.azure[*].storage_id)
}

output "storage_name" {
  description = "Name of the created object storage resource"
  value       = local.is_ovh ? one(module.ovh[*].storage_name) : one(module.azure[*].storage_name)
}

output "storage_region" {
  description = "Region of the created object storage resource"
  value       = local.is_ovh ? one(module.ovh[*].storage_region) : one(module.azure[*].storage_region)
}

output "connection_string" {
  description = "Connection string (null for OVH)"
  value       = local.is_ovh ? one(module.ovh[*].connection_string) : one(module.azure[*].connection_string)
  sensitive   = true
}
