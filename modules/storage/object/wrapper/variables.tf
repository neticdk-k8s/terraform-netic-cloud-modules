variable "cloud_provider" {
  type        = string
  description = "Cloud provider: 'ovh' or 'azure'"
  validation {
    condition     = contains(["ovh", "azure"], var.cloud_provider)
    error_message = "cloud_provider must be 'ovh' or 'azure'."
  }
}

variable "name" {
  description = "Name of the object storage resource"
  type        = string
}

variable "ovh" {
  description = "OVH object storage config. Required when cloud_provider = 'ovh'."
  type = object({
    project_id       = string
    region           = optional(string, "GRA")
    versioning       = optional(string, "enabled")
    encryption_sse   = optional(string, "AES256")
    object_lock_days = optional(number, 0)
  })
  default = null
}

variable "azure" {
  description = "Azure object storage config. Required when cloud_provider = 'azure'."
  type = object({
    resource_group   = string
    location         = string
    replication_type = optional(string, "LRS")
    versioning       = optional(bool, true)
    retention_days   = optional(number, 7)
    container_name   = optional(string, "data")
  })
  default = null
}
