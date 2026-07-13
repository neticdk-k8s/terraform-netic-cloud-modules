output "secret_ids" {
  description = "Map: secret-navn → resource ID"
  value       = { for k, s in ovh_cloud_key_manager_secret.this : k => s.id }
}
