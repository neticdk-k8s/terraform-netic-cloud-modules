output "id" {
  description = "ID på Key Manager-containeren"
  value       = ovh_cloud_key_manager_container.this.id
}

output "name" {
  description = "Navn på containeren"
  value       = ovh_cloud_key_manager_container.this.name
}

output "uri" {
  description = "Ingen vault-URI på OVH — secrets er projekt/region-scoped (altid null)"
  value       = null
}
