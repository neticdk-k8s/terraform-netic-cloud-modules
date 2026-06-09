output "security_group_id" {
  description = "ID of the security group (NSG id for Azure, OpenStack secgroup id for OVH)"
  value       = local.is_ovh ? module.ovh[0].security_group_id : module.azure[0].security_group_id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = local.is_ovh ? module.ovh[0].security_group_name : module.azure[0].security_group_name
}
