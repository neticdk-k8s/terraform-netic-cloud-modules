output "network_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the virtual network"
}

output "network_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "subnet_ids" {
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
  description = "Map of subnet names to their IDs"
}

output "nsg_ids" {
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
  description = "Map of subnet names to their NSG IDs"
}
