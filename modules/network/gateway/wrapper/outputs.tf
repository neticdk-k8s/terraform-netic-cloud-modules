output "id" {
  value       = local.is_ovh ? one(module.ovh[*].id) : one(module.azure[*].id)
  description = "ID of the created gateway"
}

output "external_information" {
  value       = local.is_ovh ? one(module.ovh[*].external_information) : one(module.azure[*].external_information)
  description = "External/outbound info — SNAT public IP(s) for OVH, public IP + subnets for Azure"
}
