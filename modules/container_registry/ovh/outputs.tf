output "registry_url" {
  description = "The public URL endpoint of the provisioned Container Registry"
  value       = var.container_registry.deploy ? ovh_cloud_project_containerregistry.registry[0].url : null
}

output "registry_id" {
  description = "ID of the Container Registry resource"
  value       = var.container_registry.deploy ? ovh_cloud_project_containerregistry.registry[0].id : null
}

output "user_passwords" {
  description = "Map of registry usernames and their generated passwords"
  value       = { for k, v in ovh_cloud_project_containerregistry_user.user : k => v.password }
  sensitive   = true
}


