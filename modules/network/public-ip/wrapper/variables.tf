variable "public_ip" {
  type = object({
    azure = optional(object({
      name            = string
      location        = string
      resource_group  = string
      prevent_destroy = optional(bool, true)
      tags            = optional(map(string), {})
    }), null)
    ovh = optional(object({
      service_name    = string
      ip              = string
      routed_to       = string
      prevent_destroy = optional(bool, false)
    }), null)
  })
  description = <<-EOT
    Public IP configuration. Set exactly one of public_ip.azure or public_ip.ovh.

    Note the providers differ: Azure CREATES a new public IP, while OVH ATTACHES a
    pre-ordered Additional IP (failover IP) to an instance — supply ip + routed_to.
    For an OVH NAT'ed pool IP use the separate network/floating-ip/ovh module.
  EOT

  validation {
    condition     = (var.public_ip.ovh != null) != (var.public_ip.azure != null)
    error_message = "Exactly one of public_ip.ovh or public_ip.azure must be set."
  }
}
