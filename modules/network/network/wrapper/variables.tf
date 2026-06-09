variable "network" {
  type = object({
    name = string

    ovh = optional(object({
      project_id = string
      vlan_id    = number
      regions = list(object({
        region              = string
        subnet              = string
        dhcp                = optional(bool, true)
        no_gateway          = optional(bool, false)
        ip_allocation_start = optional(number, 10)
        ip_allocation_stop  = optional(number, 200)
      }))
    }), null)

    azure = optional(object({
      location       = string
      resource_group = string
      address_space  = list(string)
      subnets = map(object({
        cidr = string
      }))
    }), null)
  })
  description = "Network configuration. Set exactly one of network.ovh or network.azure."

  validation {
    condition     = (var.network.ovh != null) != (var.network.azure != null)
    error_message = "Exactly one of network.ovh or network.azure must be set."
  }
}
