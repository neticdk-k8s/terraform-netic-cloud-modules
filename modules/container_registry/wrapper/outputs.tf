output "registry_url" {
  description = "URL/login server of the container registry"
  value       = local.is_ovh ? one(module.ovh[*].registry_url) : one(module.azure[*].registry_url)
}

output "registry_id" {
  description = "ID of the Container Registry resource"
  value       = local.is_ovh ? one(module.ovh[*].registry_id) : one(module.azure[*].registry_id)
}

output "user_passwords" {
  description = "Map of usernames and their generated passwords"
  value       = local.is_ovh ? one(module.ovh[*].user_passwords) : one(module.azure[*].user_passwords)
  sensitive   = true
}
