output "id" {
  value       = azurerm_nat_gateway.gw.id
  description = "Resource ID of the NAT gateway"
}

output "resource_guid" {
  value       = azurerm_nat_gateway.gw.resource_guid
  description = "Resource GUID of the NAT gateway"
}

output "external_information" {
  value = {
    public_ip_id = var.gateway.public_ip_id
    subnet_ids   = var.gateway.subnet_ids
  }
  description = "Outbound public IP resource ID and the subnets routed through the gateway"
}
