variable "storage" {
  type = object({
    name = string

    ovh = optional(object({
      project_id       = string
      region           = optional(string, "GRA")
      versioning       = optional(string, "enabled")
      encryption_sse   = optional(string, "AES256")
      object_lock_days = optional(number, 0)
    }), null)

    azure = optional(object({
      resource_group   = string
      location         = string
      replication_type = optional(string, "LRS")
      versioning       = optional(bool, true)
      retention_days   = optional(number, 7)
      container_name   = optional(string, "data")
    }), null)
  })
  description = "Object storage configuration. Set exactly one of storage.ovh or storage.azure."

  validation {
    condition     = (var.storage.ovh != null) != (var.storage.azure != null)
    error_message = "Exactly one of storage.ovh or storage.azure must be set."
  }
}
