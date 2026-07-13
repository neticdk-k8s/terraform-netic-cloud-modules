output "id" {
  description = "Resource ID of the Key Vault (use as key_vault_id i secret-modulet)"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Navn på Key Vault"
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}
