variable "port" {
  type = object({
    name          = string
    network_id    = string
    subnet_id     = optional(string, null)
    static_ip     = optional(string, null)
    ip_forwarding = optional(bool, false)
    # false = port is created WITHOUT a fixed IP in Neutron, so it gets no DHCP
    # lease at all; the guest configures its IP itself (static_ip is then only
    # informational). Requires ip_forwarding = true (no anti-spoofing), otherwise
    # traffic from the unregistered IP is dropped.
    dhcp_lease = optional(bool, true)
  })
  description = <<-EOT
    A single OpenStack (OVH) network port.

    Call this module once per port — use for_each in the caller, keyed on a
    static value (e.g. the network name), and pass the computed network_id /
    subnet_id in as values. That keeps for_each keys known at plan time.

    - static_ip:     fixed IP to assign (e.g. x.x.x.254). Requires subnet_id.
    - ip_forwarding: when true, port security is disabled (port_security_enabled
                     = false), turning off BOTH anti-spoofing AND security groups
                     on the port. Required for firewall/router/VPN VMs that
                     forward traffic not addressed to their own IP.
    - dhcp_lease:    false => no fixed IP in Neutron and therefore no DHCP lease.
                     Use on a firewall port that owns the subnet's gateway IP:
                     a lease would hand it a default route / host routes pointing
                     at itself. The guest sets static_ip itself (e.g. config.xml).
  EOT
}
