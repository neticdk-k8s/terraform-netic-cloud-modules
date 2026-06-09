output "security_group_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.nsg.id
}

output "security_group_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.nsg.name
}
