locals {
  aip = var.public_ip.prevent_destroy ? ovh_cloud_project_failover_ip_attach.aip_protected[0] : ovh_cloud_project_failover_ip_attach.aip[0]
}

output "ip_address" {
  value       = local.aip.ip
  description = "The attached Additional IP address"
}

output "id" {
  value       = local.aip.id
  description = "ID of the Additional IP block"
}
