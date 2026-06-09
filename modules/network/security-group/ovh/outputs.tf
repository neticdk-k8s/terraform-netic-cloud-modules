output "security_group_id" {
  description = "ID of the OpenStack security group"
  value       = openstack_networking_secgroup_v2.sg.id
}

output "security_group_name" {
  description = "Name of the OpenStack security group"
  value       = openstack_networking_secgroup_v2.sg.name
}
