output "storage_id" {
  description = "ID of the object storage bucket"
  value       = ovh_cloud_project_storage.storage.id
}

output "storage_name" {
  description = "Name of the object storage bucket"
  value       = ovh_cloud_project_storage.storage.name
}

output "storage_region" {
  description = "Region of the object storage bucket"
  value       = var.region
}

output "connection_string" {
  description = "Not applicable for OVH — use the S3-compatible endpoint instead"
  value       = null
  sensitive   = true
}
