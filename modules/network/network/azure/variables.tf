variable "network" {
  type = object({
    name           = string
    location       = string
    resource_group = string
    address_space  = list(string)
    subnets = map(object({
      cidr = string
    }))
  })
}
