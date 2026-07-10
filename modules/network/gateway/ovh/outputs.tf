output "id" {
  value       = ovh_cloud_project_gateway.gateway.id
  description = "ID of the OVH public cloud gateway"
}

output "status" {
  value       = ovh_cloud_project_gateway.gateway.status
  description = "Provisioning status of the gateway"
}

output "external_information" {
  value       = ovh_cloud_project_gateway.gateway.external_information
  description = "External network info incl. the gateway's SNAT public IP(s)"
}

output "interface_ids" {
  value       = { for v in ovh_cloud_project_gateway_interface.additional : v.subnet_id => v.id }
  description = "Map of additional subnet UUID to the gateway interface ID"
}
