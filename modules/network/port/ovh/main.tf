# A single network port on an existing OVH/OpenStack private network.
#
# ip_forwarding = true sets port_security_enabled = false, which disables both
# Neutron's anti-spoofing filter and security-group enforcement on this port —
# required for a VM that routes/forwards traffic not addressed to its own IP
# (firewalls, NAT/VPN gateways, etc.).
resource "openstack_networking_port_v2" "port" {
  name                  = var.port.name
  network_id            = var.port.network_id
  port_security_enabled = !var.port.ip_forwarding

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
