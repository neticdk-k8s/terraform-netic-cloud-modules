locals {
  primary_subnet_id     = var.gateway.subnet_ids[0]
  additional_subnet_ids = slice(var.gateway.subnet_ids, 1, length(var.gateway.subnet_ids))
}

# Look up the parent network of the primary subnet so callers only need to pass
# subnet IDs (network_id is required by ovh_cloud_project_gateway).
# `region` must be pinned — OpenStack's API is per-region, so without it the
# lookup hits the provider's default region and returns nothing.
data "openstack_networking_subnet_v2" "primary" {
  region    = var.gateway.region
  subnet_id = local.primary_subnet_id
}

resource "ovh_cloud_project_gateway" "gateway" {
  service_name = var.gateway.service_name
  name         = var.gateway.name
  model        = var.gateway.model
  region       = var.gateway.region
  network_id   = data.openstack_networking_subnet_v2.primary.network_id
  subnet_id    = local.primary_subnet_id
}

# Attach further private networks to the same gateway (one interface per subnet)
# so it also provides SNAT/outbound access for those subnets.
#
# Keyed by list index (statically known) rather than by subnet UUID: the UUIDs
# come from other resources/modules and are unknown at plan time, which for_each
# cannot use as keys.
resource "ovh_cloud_project_gateway_interface" "additional" {
  for_each = { for idx, sid in local.additional_subnet_ids : tostring(idx) => sid }

  service_name = var.gateway.service_name
  region       = var.gateway.region
  id           = ovh_cloud_project_gateway.gateway.id
  subnet_id    = each.value
}
