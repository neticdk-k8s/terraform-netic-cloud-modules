variable "port" {
  type = object({
    name          = string
    network_id    = string
    subnet_id     = optional(string, null)
    static_ip     = optional(string, null)
    ip_forwarding = optional(bool, false)
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
  EOT
}
