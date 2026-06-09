output "registry_url" {
  description = "Login server URL of the ACR (e.g. myregistry.azurecr.io)"
  value       = var.container_registry.deploy ? azurerm_container_registry.registry[0].login_server : null
}

output "registry_id" {
  description = "ID of the Container Registry resource"
  value       = var.container_registry.deploy ? azurerm_container_registry.registry[0].id : null
}

output "admin_username" {
  description = "Admin username for the registry"
  value       = var.container_registry.deploy ? azurerm_container_registry.registry[0].admin_username : null
}

output "admin_password" {
  description = "Admin password for the registry"
  value       = var.container_registry.deploy ? azurerm_container_registry.registry[0].admin_password : null
  sensitive   = true
}

output "user_passwords" {
  description = "Map of token usernames and their generated passwords"
  value       = { for k, v in azurerm_container_registry_token_password.user_password : k => v.password1[0].value }
  sensitive   = true
}


