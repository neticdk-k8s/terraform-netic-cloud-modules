variable "security_group" {
  type = object({
    name           = string
    location       = string
    resource_group = string
    rules = optional(list(object({
      name      = string
      direction = string                # ingress / egress
      protocol  = string                # tcp, udp, icmp, *
      port      = optional(string, "*") # "80", "8080-8090", "*"
      cidr      = optional(string, "*")
      access    = optional(string, "Allow") # Allow / Deny
    })), [])
  })
}
