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
    # static_ip/ip_forwarding/network_security_group_id are deliberately NOT
    # optional(): if one holds a not-yet-known value (e.g. a subnet or NSG
    # created in the same apply), Terraform/OpenTofu has to fully resolve
    # optional-attribute defaults for the whole object, which turns the
    # entire object unknown and breaks for_each downstream. Pass all fields
    # explicitly (null/false where not applicable).
    networks = optional(list(object({
      subnet_id                 = string
      static_ip                 = string
      ip_forwarding             = bool
      network_security_group_id = string
    })), [])
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
