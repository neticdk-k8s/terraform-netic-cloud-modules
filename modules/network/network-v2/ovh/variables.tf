variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "network" {
  type = object({
    name    = string
    vlan_id = number
    regions = list(object({
      region          = string
      subnet          = string
      dhcp            = optional(bool, true)
      no_gateway      = optional(bool, false)
      dns_nameservers = optional(list(string), null) # null = OVH's default public DNS resolver (advertised via DHCP)
      gateway_host    = optional(number, null)       # host index in the CIDR for the gateway, e.g. 254 => x.x.x.254. null = OVH default (first IP)
      host_routes = optional(list(object({           # static routes pushed via DHCP (option 121), managed via openstack_networking_subnet_route_v2
        destination = string                         # CIDR, e.g. "192.168.24.0/22"
        nexthop     = string                         # IP on this subnet, e.g. "10.0.25.254"
      })), [])
    }))
  })

  validation {
    condition = alltrue([
      for r in var.network.regions : r.gateway_host == null || !r.no_gateway
    ])
    error_message = "gateway_host cannot be combined with no_gateway = true."
  }

  description = <<-EOT
    OVH vRack private network using the v2 subnet resource
    (ovh_cloud_project_network_private_subnet_v2), which — unlike the classic
    subnet — advertises DNS resolvers over DHCP.

      - dns_nameservers: custom resolvers, e.g. ["1.1.1.1"]. Leave null to use
        OVH's default public resolver (use_default_public_dns_resolver = true).
      - no_gateway:      true disables the subnet gateway IP (no default route).
      - gateway_host:    host index of a custom gateway (e.g. 254 for an NVA/firewall
                         on .254). Cannot be combined with no_gateway = true.
      - host_routes:     extra static routes advertised over DHCP, e.g. a VPN range
                         via the firewall. Works with or without a default gateway.

    The IP allocation pool is left to OVH (whole CIDR minus the reserved
    gateway) — this avoids the gateway address landing inside a manually set pool.
  EOT
}
