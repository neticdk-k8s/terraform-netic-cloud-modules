# A single network port on an existing OVH/OpenStack network.
#
# ip_forwarding = true sets port_security_enabled = false, which disables both
# Neutron's anti-spoofing filter and security-group enforcement on this port —
# required for a VM that routes/forwards traffic not addressed to its own IP
# (firewalls, NAT/VPN gateways, etc.).
#
# When ip_forwarding = false we leave port_security_enabled UNSET (null) rather
# than forcing it to true: OVH's external network (Ext-Net) rejects any port
# create that sets the attribute at all (PolicyNotAuthorized), so a WAN port
# must inherit the network default instead of stating it explicitly.
resource "openstack_networking_port_v2" "port" {
  name                  = var.port.name
  network_id            = var.port.network_id
  port_security_enabled = var.port.ip_forwarding ? false : null

  dynamic "fixed_ip" {
    for_each = var.port.static_ip != null ? [1] : []
    content {
      subnet_id  = var.port.subnet_id
      ip_address = var.port.static_ip
    }
  }

  lifecycle {
    precondition {
      condition     = var.port.static_ip == null || var.port.subnet_id != null
      error_message = "port.subnet_id must be set when port.static_ip is set."
    }
  }
}
