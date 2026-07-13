output "secret_ids" {
  description = "Map: secret-navn → resource ID"
  value       = local.is_ovh ? one(module.ovh[*].secret_ids) : one(module.azure[*].secret_ids)
}
