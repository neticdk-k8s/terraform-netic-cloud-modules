locals {
  pip = var.public_ip.prevent_destroy ? azurerm_public_ip.pip_protected[0] : azurerm_public_ip.pip[0]
}

output "ip_address" {
  value       = local.pip.ip_address
  description = "The allocated public IP address"
}

output "id" {
  value       = local.pip.id
  description = "Resource ID of the public IP (used when attaching to a NIC)"
}
