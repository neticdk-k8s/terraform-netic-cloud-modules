resource "ovh_cloud_project_network_private" "net" {
  service_name = var.ovh_project_id
  name         = var.network.name
  vlan_id      = var.network.vlan_id
  regions = [
    for r in var.network.regions : r.region
  ]
}

# The v2 subnet's network_id must be the OpenStack network UUID (NOT the pn-xxx
# OVH id) — a known provider gotcha. Resolve it per region, pinned to that
# region's Neutron endpoint.
data "openstack_networking_network_v2" "net" {
  for_each = {
    for r in var.network.regions : r.region => r
  }
  region     = each.value.region
  name       = var.network.name
  depends_on = [ovh_cloud_project_network_private.net]
}

resource "ovh_cloud_project_network_private_subnet_v2" "subnet" {
  for_each = {
    for r in var.network.regions : r.region => r
  }

  service_name = var.ovh_project_id
  network_id   = data.openstack_networking_network_v2.net[each.key].id
  name         = "${var.network.name}-${each.value.region}"
  region       = each.value.region
  cidr         = each.value.subnet
  dhcp         = each.value.dhcp

  # Default route: enable the subnet gateway IP unless explicitly disabled.
  enable_gateway_ip = !each.value.no_gateway

  # DNS over DHCP: use OVH's default resolver unless custom servers are given.
  # (Passing an explicit list flips use_default_public_dns_resolver to false.)
  dns_nameservers                 = each.value.dns_nameservers
  use_default_public_dns_resolver = each.value.dns_nameservers == null
}
