variable "security_group" {
  type = object({
    name = string
    rules = optional(list(object({
      name      = string
      direction = string           # ingress / egress
      protocol  = string           # tcp, udp, icmp, *
      port      = optional(string, "*") # "80", "8080-8090", "*"
      cidr      = optional(string, "*")
      access    = optional(string, "Allow") # Azure only: Allow / Deny
      ethertype = optional(string, "IPv4")  # OVH only: IPv4 / IPv6
    })), [])

    azure = optional(object({
      location       = string
      resource_group = string
    }), null)

    ovh = optional(object({}), null)
  })
  description = "Security group configuration. Set exactly one of security_group.azure or security_group.ovh."

  validation {
    condition     = (var.security_group.azure != null) != (var.security_group.ovh != null)
    error_message = "Exactly one of security_group.azure or security_group.ovh must be set."
  }
}
