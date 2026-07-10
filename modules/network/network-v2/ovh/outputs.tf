output "network_id" {
  description = "OpenStack UUID of the private network in the first region (single-region use; see network_ids)"
  value       = data.openstack_networking_network_v2.net[var.network.regions[0].region].id
}

output "network_ids" {
  description = "Map of region to the OpenStack UUID of the private network in that region"
  value = {
    for k, v in data.openstack_networking_network_v2.net : k => v.id
  }
}

output "network_name" {
  description = "Name of the private network"
  value       = ovh_cloud_project_network_private.net.name
}

output "subnet_ids" {
  description = "Map of region to OpenStack subnet UUID"
  value = {
    for k, v in ovh_cloud_project_network_private_subnet_v2.subnet : k => v.id
  }
}

output "gateway_ips" {
  description = "Map of region to the subnet's gateway IP (the default route handed out via DHCP)"
  value = {
    for k, v in ovh_cloud_project_network_private_subnet_v2.subnet : k => v.gateway_ip
  }
}
