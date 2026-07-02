variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "vm" {
  type = object({
    name             = string
    size             = string
    location         = string
    image_name       = string
    os_type          = optional(string, "Linux")
    resource_group   = string
    create_public_ip = optional(bool, false)
    ssh_public_key   = optional(string, null)
    admin_pass       = optional(string, null)
    networks = optional(list(object({
      name          = string
      network_id    = optional(string, null)
      subnet_id     = optional(string, null)
      static_ip     = optional(string, null)
      ip_forwarding = optional(bool, false)
    })), [])
    power_state     = optional(string, "active")
    user_data       = optional(string, null)
    security_groups = optional(list(string), ["default"])
    tags            = optional(map(string), {})
  })

  validation {
    condition     = !contains([for n in var.vm.networks : n.name], "Ext-Net")
    error_message = "Ext-Net must not be in networks — set create_public_ip = true instead."
  }

  validation {
    condition = alltrue([
      for n in var.vm.networks : n.network_id != null
      if n.static_ip != null || n.ip_forwarding
    ])
    error_message = "networks[].network_id must be set when static_ip is set or ip_forwarding is true (a dedicated port has to be created)."
  }

  validation {
    condition = alltrue([
      for n in var.vm.networks : n.subnet_id != null
      if n.static_ip != null
    ])
    error_message = "networks[].subnet_id must be set when static_ip is set."
  }
}
