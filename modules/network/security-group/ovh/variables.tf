variable "security_group" {
  type = object({
    name = string
    rules = optional(list(object({
      name      = string
      direction = string                # ingress / egress
      protocol  = string                # tcp, udp, icmp, *
      port      = optional(string, "*") # "80", "8080-8090", "*"
      cidr      = optional(string, "0.0.0.0/0")
      ethertype = optional(string, "IPv4")
    })), [])
  })
}
