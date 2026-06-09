output "storage_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "storage_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_region" {
  description = "Region of the storage account"
  value       = var.location
}

output "connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}
