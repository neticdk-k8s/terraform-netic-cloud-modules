# An OVH private network materializes as a separate OpenStack network (with its
# own UUID) in each region it spans, and OpenStack's API is per-region. Both
# lookups are therefore keyed per region and pin `region` explicitly — otherwise
# they hit the provider's default region and return nothing for other regions.
data "openstack_networking_network_v2" "net" {
  for_each = {
    for r in var.network.regions : r.region => r
  }
  region     = each.value.region
  name       = var.network.name
  depends_on = [ovh_cloud_project_network_private.net]
}

data "openstack_networking_subnet_v2" "subnet" {
  for_each = {
    for r in var.network.regions : r.region => r
  }
  region     = each.value.region
  cidr       = each.value.subnet
  network_id = data.openstack_networking_network_v2.net[each.key].id
  depends_on = [ovh_cloud_project_network_private_subnet.subnet]
}

resource "ovh_cloud_project_network_private" "net" {
  service_name = var.ovh_project_id
  name         = var.network.name
  vlan_id      = var.network.vlan_id
  regions = [
    for r in var.network.regions : r.region
  ]
}

resource "ovh_cloud_project_network_private_subnet" "subnet" {
  for_each = {
    for r in var.network.regions : r.region => r
  }
  service_name = var.ovh_project_id
  network_id   = ovh_cloud_project_network_private.net.id

  region     = each.value.region
  network    = each.value.subnet
  start      = cidrhost(each.value.subnet, each.value.ip_allocation_start)
  end        = cidrhost(each.value.subnet, each.value.ip_allocation_stop)
  dhcp       = each.value.dhcp
  no_gateway = each.value.no_gateway
}
