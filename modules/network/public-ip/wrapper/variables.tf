variable "public_ip" {
  type = object({
    name            = string
    location        = string
    resource_group  = string
    prevent_destroy = optional(bool, false)
    tags            = optional(map(string), {})

    ovh   = optional(object({}), null)
    azure = optional(object({}), null)
  })
  description = "Public IP configuration. Set exactly one of public_ip.ovh or public_ip.azure. prevent_destroy defaults to false."

  validation {
    condition     = (var.public_ip.ovh != null) != (var.public_ip.azure != null)
    error_message = "Exactly one of public_ip.ovh or public_ip.azure must be set."
  }
}
