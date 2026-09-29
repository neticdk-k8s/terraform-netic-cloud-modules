variable "network" {
  type = object({
    name = string
    tags = optional(map(string), {}) # applied where the cloud supports it (Azure vnet/NSG) — OVH private networks have no tags

    ovh = optional(object({
      project_id = string
      vlan_id    = number
      regions = list(object({
        region              = string
        subnet              = string
        dhcp                = optional(bool, true)
        no_gateway          = optional(bool, false)
        ip_allocation_start = optional(number, 10)  # null (with stop) = OVH uses whole CIDR
        ip_allocation_stop  = optional(number, 200)
        dns_nameservers     = optional(list(string), null) # null = OVH default resolver via DHCP
        gateway_host        = optional(number, null)       # e.g. 254 => firewall on x.x.x.254 is default gw
        host_routes = optional(list(object({               # static routes via DHCP (option 121)
          destination = string
          nexthop     = string
        })), [])
      }))
    }), null)

    azure = optional(object({
      location       = string
      resource_group = string
      address_space  = list(string)
      subnets = map(object({
        cidr = string
      }))
      create_default_nsgs = optional(bool, true) # auto-NSG pr. subnet — slå fra hvis NSG'er styres separat (fx via security-group-modulet)
    }), null)
  })
  description = "Network configuration. Set exactly one of network.ovh or network.azure."

  validation {
    condition     = (var.network.ovh != null) != (var.network.azure != null)
    error_message = "Exactly one of network.ovh or network.azure must be set."
  }
}
