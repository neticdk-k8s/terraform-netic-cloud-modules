locals {
  fip = var.public_ip.prevent_destroy ? openstack_networking_floatingip_v2.fip_protected[0] : openstack_networking_floatingip_v2.fip[0]
}

output "ip_address" {
  value       = local.fip.address
  description = "The reserved floating IP address"
}

output "id" {
  value       = local.fip.id
  description = "ID of the floating IP (used for association with a VM port)"
}
