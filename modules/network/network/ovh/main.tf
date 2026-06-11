data "openstack_networking_network_v2" "net" {
  name       = var.network.name
  depends_on = [ovh_cloud_project_network_private.net]
}

data "openstack_networking_subnet_v2" "subnet" {
  for_each = {
    for r in var.network.regions : r.region => r
  }
  cidr       = each.value.subnet
  network_id = data.openstack_networking_network_v2.net.id
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
