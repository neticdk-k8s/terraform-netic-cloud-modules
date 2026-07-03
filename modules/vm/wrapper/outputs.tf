output "vm_name" {
  description = "Name of the created virtual machine"
  value       = local.is_ovh ? one(module.ovh[*].vm_name) : one(module.azure[*].vm_name)
}

output "vm_ip" {
  description = "Primary private IPv4 address"
  value       = local.is_ovh ? one(module.ovh[*].vm_ip) : one(module.azure[*].vm_ip)
}

output "public_ip" {
  description = "Public IP address (null if not configured)"
  value       = local.is_ovh ? one(module.ovh[*].public_ip) : one(module.azure[*].public_ip)
}

output "ssh_private_key" {
  description = "Generated SSH private key in PEM format (null if a key was provided)"
  value       = local.is_ovh ? one(module.ovh[*].ssh_private_key) : one(module.azure[*].ssh_private_key)
  sensitive   = true
}

output "network_interface_ids" {
  description = "IDs of all NICs in the same order as vm.azure.networks (Azure only — null for OVH, where attachments are ports; see vm.ovh.port_ids)"
  value       = local.is_ovh ? null : one(module.azure[*].network_interface_ids)
}
