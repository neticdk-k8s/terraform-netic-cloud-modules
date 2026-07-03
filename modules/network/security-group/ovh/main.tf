locals {
  rules_parsed = [
    for r in var.security_group.rules : {
      name      = r.name
      direction = r.direction
      # OpenStack: null protocol means "all"
      protocol  = r.protocol == "*" ? null : r.protocol
      ethertype = r.ethertype
      # OpenStack requires a valid CIDR (or null = any) — "*" is Azure syntax
      cidr = r.cidr == "*" ? null : r.cidr
      # Parse port: "*" → null, "80" → [80,80], "8080-8090" → [8080,8090]
      port_min = r.port == "*" ? null : tonumber(split("-", r.port)[0])
      port_max = r.port == "*" ? null : tonumber(split("-", r.port)[length(split("-", r.port)) - 1])
    }
  ]
}

resource "openstack_networking_secgroup_v2" "sg" {
  name        = var.security_group.name
  description = "Managed by Terraform"
  tags        = [for k, v in var.security_group.tags : "${k}:${v}"]
}

resource "openstack_networking_secgroup_rule_v2" "rule" {
  for_each = { for r in local.rules_parsed : r.name => r }

  security_group_id = openstack_networking_secgroup_v2.sg.id
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  port_range_min    = each.value.port_min
  port_range_max    = each.value.port_max
  remote_ip_prefix  = each.value.cidr
}
