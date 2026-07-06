variable "floating_ip" {
  type = object({
    name            = string
    resource_group  = string
    prevent_destroy = optional(bool, false)
    tags            = optional(map(string), {})
  })
  description = "Floating IP configuration. Reserves a NAT'ed floating IP from OVH's Ext-Net pool."
}
