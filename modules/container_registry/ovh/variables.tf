variable "ovh_project_id" {
  type        = string
  description = "OVH Cloud project service ID"
}

variable "container_registry" {
  type = object({
    deploy = bool
    name   = string
    region = string
  })
  description = "Configuration of OVH Container Registry"
}

variable "registry_users" {
  type = list(object({
    login = string
    email = string
  }))
  description = "List of user accounts to create in the container registry"
  default     = []
}

variable "ip_restrictions" {
  type = list(object({
    ip_block    = string
    description = string
  }))
  default     = []
  description = "List of IP blocks allowed to access the container registry. Leave empty for no restrictions."
}
