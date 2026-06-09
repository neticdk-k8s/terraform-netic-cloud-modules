variable "cloud_provider" {
  type        = string
  description = "Cloud provider: 'ovh' or 'azure'"
  validation {
    condition     = contains(["ovh", "azure"], var.cloud_provider)
    error_message = "cloud_provider must be 'ovh' or 'azure'."
  }
}

variable "container_registry" {
  type = object({
    deploy = bool
    name   = string
  })
  description = "Common registry configuration shared across cloud providers"
}

variable "registry_users" {
  type = list(object({
    login = string
    email = string
  }))
  default     = []
  description = "Users to create in the registry"
}

variable "ip_restrictions" {
  type = list(object({
    ip_block    = string
    description = string
  }))
  default     = []
  description = "IP ranges allowed to access the registry"
}

variable "ovh_config" {
  type = object({
    project_id = string
    region     = string
  })
  default     = null
  description = "OVH-specific config. Required when cloud_provider = 'ovh'."
}

variable "azure_config" {
  type = object({
    location       = string
    resource_group = string
    sku            = optional(string, "Basic")
  })
  default     = null
  description = "Azure-specific config. Required when cloud_provider = 'azure'. IP restrictions require sku = 'Premium'."
}
