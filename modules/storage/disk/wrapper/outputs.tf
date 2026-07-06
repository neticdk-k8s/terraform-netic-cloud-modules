output "id" {
  description = "Disk ID (volume UUID for OVH, managed disk resource ID for Azure)"
  value       = local.is_ovh ? one(module.ovh[*].id) : one(module.azure[*].id)
}

output "name" {
  description = "Disk name"
  value       = local.is_ovh ? one(module.ovh[*].name) : one(module.azure[*].name)
}
