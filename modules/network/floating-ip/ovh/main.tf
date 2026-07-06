locals {
  tags = [for k, v in var.floating_ip.tags : "${k}:${v}"]
}

resource "openstack_networking_floatingip_v2" "fip" {
  count       = var.floating_ip.prevent_destroy ? 0 : 1
  pool        = "Ext-Net"
  description = var.floating_ip.name
  tags        = concat(local.tags, ["resource_group:${var.floating_ip.resource_group}"])
}

resource "openstack_networking_floatingip_v2" "fip_protected" {
  count       = var.floating_ip.prevent_destroy ? 1 : 0
  pool        = "Ext-Net"
  description = var.floating_ip.name
  tags        = concat(local.tags, ["resource_group:${var.floating_ip.resource_group}"])

  lifecycle {
    prevent_destroy = true
  }
}
