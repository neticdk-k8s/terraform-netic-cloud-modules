output "id" {
  description = "OKMS-instansens ID (okms_id) — bruges som input til secret-modulet"
  value       = ovh_okms.this.id
}

output "name" {
  description = "Display-navn på OKMS-instansen"
  value       = ovh_okms.this.display_name
}

output "uri" {
  description = "REST-endpoint til OKMS"
  value       = ovh_okms.this.rest_endpoint
}
