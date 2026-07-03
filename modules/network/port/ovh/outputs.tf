output "id" {
  description = "OpenStack port UUID — pass to a VM via vm.ovh.port_ids"
  value       = openstack_networking_port_v2.port.id
}

locals {
  _fixed_ips = tolist(openstack_networking_port_v2.port.all_fixed_ips)
  # IPv6 addresses contain ":", IPv4 do not — split the list on that.
  _ipv4s = [for ip in local._fixed_ips : ip if length(regexall(":", ip)) == 0]
  _ipv6s = [for ip in local._fixed_ips : ip if length(regexall(":", ip)) > 0]
}

output "ip_address" {
  description = "Fixed IP assigned to the port, IPv4 preferred (an Ext-Net port often gets both v4 and v6). Null if none."
  value       = try(local._ipv4s[0], local._fixed_ips[0], null)
}

output "ipv4_address" {
  description = "First IPv4 fixed IP (null if none)"
  value       = try(local._ipv4s[0], null)
}

output "ipv6_address" {
  description = "First IPv6 fixed IP (null if none)"
  value       = try(local._ipv6s[0], null)
}

output "mac_address" {
  description = "MAC address of the port — useful for matching the port to the guest's interface (e.g. FreeBSD vtnetN ordering)"
  value       = openstack_networking_port_v2.port.mac_address
}
