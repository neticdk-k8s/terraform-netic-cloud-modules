variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "network" {
  type = object({
    name    = string
    vlan_id = number
    regions = list(object({
      region              = string
      subnet              = string
      dhcp                = optional(bool, true)
      no_gateway          = optional(bool, false)
      ip_allocation_start = optional(number, 10)
      ip_allocation_stop  = optional(number, 200)
    }))
  })
}
