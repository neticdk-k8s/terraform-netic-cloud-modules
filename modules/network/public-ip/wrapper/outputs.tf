output "ip_address" {
  value       = local.is_ovh ? one(module.ovh[*].ip_address) : one(module.azure[*].ip_address)
  description = "The allocated public IP address"
}

output "id" {
  value       = local.is_ovh ? one(module.ovh[*].id) : one(module.azure[*].id)
  description = "ID of the public IP resource (floating IP ID for OVH, resource ID for Azure)"
}
