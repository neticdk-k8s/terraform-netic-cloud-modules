output "network_id" {
  description = "OpenStack UUID of the private network (useful in openstack_networking_port_v2 etc.)"
  value       = data.openstack_networking_network_v2.net.id
}

output "network_name" {
  description = "Name of the private network"
  value       = ovh_cloud_project_network_private.net.name
}

output "subnet_ids" {
  description = "Map of region to OpenStack subnet UUID"
  value = {
    for k, v in data.openstack_networking_subnet_v2.subnet : k => v.id
  }
}
