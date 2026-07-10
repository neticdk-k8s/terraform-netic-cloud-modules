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
    }))
  })
  description = <<-EOT
    OVH vRack private network using the v2 subnet resource
    (ovh_cloud_project_network_private_subnet_v2), which — unlike the classic
    subnet — advertises DNS resolvers over DHCP.

      - dns_nameservers: custom resolvers, e.g. ["1.1.1.1"]. Leave null to use
        OVH's default public resolver (use_default_public_dns_resolver = true).
      - no_gateway:      true disables the subnet gateway IP (no default route).

    The IP allocation pool is left to OVH (whole CIDR minus the reserved
    gateway) — this avoids the gateway address landing inside a manually set pool.
  EOT
}
