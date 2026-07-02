output "id" {
  description = "OpenStack port UUID — pass to a VM via vm.ovh.port_ids"
  value       = openstack_networking_port_v2.port.id
}

output "ip_address" {
  description = "The first fixed IP assigned to the port (null if none)"
  value       = try(tolist(openstack_networking_port_v2.port.all_fixed_ips)[0], null)
}
