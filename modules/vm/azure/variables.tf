variable "vm" {
  type = object({
    name             = string
    size             = string
    location         = string
    resource_group   = string
    os_type          = optional(string, "Linux")
    admin_username   = optional(string, "azureuser")
    admin_pass       = optional(string, null)
    ssh_public_key   = optional(string, null)
    create_public_ip = optional(bool, false)
    user_data        = optional(string, null)
    tags             = optional(map(string), {})
    networks = list(object({
      subnet_id                 = string
      static_ip                 = optional(string, null)
      ip_forwarding             = optional(bool, false)
      network_security_group_id = optional(string, null)
    }))
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
    })
  })
  description = "VM configuration. os_type must be 'Linux' or 'Windows'. admin_pass is required for Windows. networks[0] is the primary NIC and receives the public IP when create_public_ip = true."

  validation {
    condition     = length(var.vm.networks) > 0
    error_message = "vm.networks must contain at least one entry."
  }
}
