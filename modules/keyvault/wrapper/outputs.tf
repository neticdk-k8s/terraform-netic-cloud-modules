output "id" {
  description = "Vault-ID — brug som input til keyvault/secret-modulet (Azure: key_vault_id)"
  value       = local.is_ovh ? one(module.ovh[*].id) : one(module.azure[*].id)
}

output "name" {
  description = "Navn på vaulten/containeren"
  value       = local.is_ovh ? one(module.ovh[*].name) : one(module.azure[*].name)
}

output "uri" {
  description = "Vault URI (null på OVH)"
  value       = local.is_ovh ? one(module.ovh[*].uri) : one(module.azure[*].uri)
}
