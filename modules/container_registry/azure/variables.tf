variable "container_registry" {
  type = object({
    deploy         = bool
    name           = string
    location       = string
    resource_group = string
    sku            = optional(string, "Basic")
    tags           = optional(map(string), {})
  })
  description = "ACR configuration. IP restrictions require sku = 'Premium'. Name must be globally unique, 5-50 alphanumeric characters."
}

variable "registry_users" {
  type = list(object({
    login = string
    email = string
  }))
  description = "Users to create as ACR tokens with read/write scope across all repositories"
  default     = []
}

variable "ip_restrictions" {
  type = list(object({
    ip_block    = string
    description = string
  }))
  default     = []
  description = "IP ranges allowed to access the registry. Requires sku = 'Premium'."
}
