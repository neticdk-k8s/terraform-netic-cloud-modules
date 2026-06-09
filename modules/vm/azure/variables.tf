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
    subnet_id        = string
    create_public_ip = optional(bool, false)
    user_data        = optional(string, null)
    tags             = optional(map(string), {})
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
    })
  })
  description = "VM configuration. os_type must be 'Linux' or 'Windows'. admin_pass is required for Windows."
}
