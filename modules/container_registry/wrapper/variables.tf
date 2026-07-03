variable "container_registry" {
  type = object({
    deploy = bool
    name   = string
    tags   = optional(map(string), {}) # Azure only — OVH registries have no tags

    ovh = optional(object({
      project_id = string
      region     = string
    }), null)

    azure = optional(object({
      location       = string
      resource_group = string
      sku            = optional(string, "Basic")
    }), null)
  })
  description = "Registry configuration. Set exactly one of container_registry.ovh or container_registry.azure. Azure: IP restrictions require sku = 'Premium'."

  validation {
    condition     = (var.container_registry.ovh != null) != (var.container_registry.azure != null)
    error_message = "Exactly one of container_registry.ovh or container_registry.azure must be set."
  }
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
