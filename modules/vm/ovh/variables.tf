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
    network_names    = optional(list(string), [])
    port_ids         = optional(list(string), [])
    power_state      = optional(string, "active")
    user_data        = optional(string, null)
    security_groups  = optional(list(string), ["default"])
    tags             = optional(map(string), {})
  })

  validation {
    condition     = !contains(var.vm.network_names, "Ext-Net")
    error_message = "Ext-Net must not be in network_names — set create_public_ip = true instead."
  }
}
