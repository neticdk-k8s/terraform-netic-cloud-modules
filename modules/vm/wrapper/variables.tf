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

    # OVH: attach networks by name (network_names) and/or by pre-created port ID
    # (port_ids). Ports that need port security disabled (ip_forwarding) are
    # created separately via modules/network/port/ovh and passed in as port_ids.
    ovh = optional(object({
      project_id      = string
      image_name      = string
      network_names   = optional(list(string), [])
      port_ids        = optional(list(string), [])
      power_state     = optional(string, "active")
      security_groups = optional(list(string), ["default"])
    }), null)

    # Azure: no separate port object exists — IP forwarding is a NIC property,
    # so it lives here per network entry. Only subnet_id is required; the rest
    # default to null/false. (Safe because NICs use count, not for_each — see
    # modules/vm/azure/variables.tf for the network_security_group_id caveat.)
    azure = optional(object({
      admin_username = optional(string, "azureuser")
      networks = optional(list(object({
        subnet_id                 = string
        static_ip                 = optional(string, null)
        ip_forwarding             = optional(bool, false)
        network_security_group_id = optional(string, null)
      })), [])
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
