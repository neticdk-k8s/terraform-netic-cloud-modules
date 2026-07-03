variable "network" {
  type = object({
    name           = string
    location       = string
    resource_group = string
    address_space  = list(string)
    subnets = map(object({
      cidr = string
    }))
    # Auto-create an (empty) NSG per subnet + association. Disable when NSGs
    # are managed separately (e.g. via the security-group module on the NIC) —
    # two NSG layers (subnet + NIC) both apply and can be confusing to debug.
    create_default_nsgs = optional(bool, true)
    tags                = optional(map(string), {})
  })
}
