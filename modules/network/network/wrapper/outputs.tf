output "network_id" {
  value       = local.is_ovh ? one(module.ovh[*].network_id) : one(module.azure[*].network_id)
  description = "ID of the created network"
}

output "network_name" {
  value       = local.is_ovh ? one(module.ovh[*].network_name) : one(module.azure[*].network_name)
  description = "Name of the network"
}

output "subnet_ids" {
  value       = local.is_ovh ? one(module.ovh[*].subnet_ids) : one(module.azure[*].subnet_ids)
  description = "Map of subnet name/region to subnet ID"
}

output "network_ids" {
  value       = local.is_ovh ? one(module.ovh[*].network_ids) : null
  description = "Map of region to OpenStack network UUID (OVH only, null for Azure)"
}

output "nsg_ids" {
  value       = local.is_ovh ? null : one(module.azure[*].nsg_ids)
  description = "Map of subnet names to NSG IDs (Azure only, null for OVH)"
}
