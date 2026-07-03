variable "security_group" {
  type = object({
    name = string
    tags = optional(map(string), {}) # Azure: NSG tags. OVH: converted to "key:value" strings on the secgroup
    rules = optional(list(object({
      name      = string
      direction = string                # ingress / egress
      protocol  = string                # tcp, udp, icmp, *
      port      = optional(string, "*") # "80", "8080-8090", "*"
      cidr      = optional(string, "*")
      access    = optional(string, "Allow") # Azure only: Allow / Deny (Deny rejected on OVH)
      priority  = optional(number, null)    # Azure only: explicit NSG priority — null = auto (100, 110, 120, … by list position)
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

  # OpenStack security groups are allow-only. Without this check a Deny rule
  # would silently become an Allow on OVH — fail loudly instead.
  validation {
    condition = var.security_group.ovh == null || alltrue([
      for r in var.security_group.rules : lower(r.access) != "deny"
    ])
    error_message = "OpenStack (OVH) security groups are allow-only — rules with access = \"Deny\" are not supported. Model the policy with Allow rules instead."
  }
}
