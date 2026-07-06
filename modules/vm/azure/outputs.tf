output "vm_name" {
  description = "The name of the created virtual machine"
  value       = local.is_windows ? one(azurerm_windows_virtual_machine.vm[*].name) : one(azurerm_linux_virtual_machine.vm[*].name)
}

output "vm_ip" {
  description = "Private IPv4 address of the VM's primary NIC (networks[0])"
  value       = azurerm_network_interface.nic[0].private_ip_address
}

output "network_interface_ids" {
  description = "IDs of all NICs, in the same order as vm.networks"
  value       = azurerm_network_interface.nic[*].id
}

output "public_ip" {
  description = "Public IP address (null if create_public_ip = false)"
  value       = var.vm.create_public_ip ? azurerm_public_ip.public_ip[0].ip_address : null
}

output "ssh_private_key" {
  description = "Generated SSH private key in PEM format. null if ssh_public_key was provided."
  value       = local.create_ssh_key ? tls_private_key.ssh_key[0].private_key_pem : null
  sensitive   = true
}
