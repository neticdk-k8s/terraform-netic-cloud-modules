variable "vm" {
  type = object({
    name             = string
    size             = string
    location         = string
    resource_group   = string
    admin_pass       = optional(string, null)
    user_data        = optional(string, null)
    os_type          = optional(string, "Linux")
    ssh_public_key   = optional(string, null)
    create_public_ip = optional(bool, false)

    ovh = optional(object({
      project_id      = string
      image_name      = string
      network_names   = optional(list(string), [])
      port_ids        = optional(list(string), [])
      power_state     = optional(string, "active")
      security_groups = optional(list(string), ["default"])
    }), null)

    azure = optional(object({
      subnet_id      = string
      admin_username = optional(string, "azureuser")
      image = object({
        publisher = string
        offer     = string
        sku       = string
        version   = optional(string, "latest")
      })
    }), null)

    tags = optional(map(string), {})
  })
  description = "VM configuration. Set exactly one of vm.ovh or vm.azure for the target provider."

  validation {
    condition     = (var.vm.ovh != null) != (var.vm.azure != null)
    error_message = "Exactly one of vm.ovh or vm.azure must be set."
  }
}
