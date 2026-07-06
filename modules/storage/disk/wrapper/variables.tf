variable "disk" {
  type = object({
    name    = string
    size_gb = number
    tags    = optional(map(string), {}) # Azure only — OpenStack volumes have no tags here

    ovh = optional(object({
      volume_type = optional(string, "classic") # classic | high-speed | high-speed-gen2
    }), null)

    azure = optional(object({
      resource_group       = string
      location             = string
      storage_account_type = optional(string, "Premium_LRS")
      zone                 = optional(string, null)
    }), null)
  })
  description = "Data disk configuration. Set exactly one of disk.ovh or disk.azure."

  validation {
    condition     = (var.disk.ovh != null) != (var.disk.azure != null)
    error_message = "Exactly one of disk.ovh or disk.azure must be set."
  }
}
