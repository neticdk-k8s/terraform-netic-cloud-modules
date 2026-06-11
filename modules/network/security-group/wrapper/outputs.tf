output "security_group_id" {
  description = "ID of the security group (NSG id for Azure, OpenStack secgroup id for OVH)"
  value       = local.is_ovh ? one(module.ovh[*].security_group_id) : one(module.azure[*].security_group_id)
}

output "security_group_name" {
  description = "Name of the security group"
  value       = local.is_ovh ? one(module.ovh[*].security_group_name) : one(module.azure[*].security_group_name)
}
