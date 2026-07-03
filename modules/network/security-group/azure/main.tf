locals {
  # Map direction ingress/egress → Inbound/Outbound
  direction_map = {
    ingress = "Inbound"
    egress  = "Outbound"
  }

  # Map protocol * / tcp / udp / icmp → Azure casing
  protocol_map = {
    "*"    = "*"
    "tcp"  = "Tcp"
    "udp"  = "Udp"
    "icmp" = "Icmp"
  }

  # Explicit priority wins; otherwise auto-assign by list position (100, 110, …).
  # NB: with auto-assignment, reordering the rules list changes priorities —
  # set priority explicitly on rules whose relative order matters.
  rules_indexed = [
    for i, r in var.security_group.rules : merge(r, { priority = r.priority != null ? r.priority : 100 + i * 10 })
  ]
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group.name
  location            = var.security_group.location
  resource_group_name = var.security_group.resource_group
  tags                = var.security_group.tags
}

resource "azurerm_network_security_rule" "rule" {
  for_each = { for r in local.rules_indexed : r.name => r }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = local.direction_map[each.value.direction]
  access                      = each.value.access
  protocol                    = local.protocol_map[each.value.protocol]
  source_port_range           = "*"
  destination_port_range      = each.value.port
  source_address_prefix       = each.value.direction == "ingress" ? each.value.cidr : "*"
  destination_address_prefix  = each.value.direction == "egress" ? each.value.cidr : "*"
  resource_group_name         = var.security_group.resource_group
  network_security_group_name = azurerm_network_security_group.nsg.name
}
