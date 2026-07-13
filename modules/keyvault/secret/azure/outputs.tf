output "secret_ids" {
  description = "Map: secret-navn → versioned resource ID"
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.id }
}

output "secret_versionless_ids" {
  description = "Map: secret-navn → versionless ID (peger altid på nyeste version)"
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.versionless_id }
}
