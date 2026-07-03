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
    zone             = optional(string, null) # availability zone ("1"/"2"/"3"), null = no zone
    boot_diagnostics = optional(bool, false)  # managed-storage boot diagnostics

    os_disk = optional(object({
      size_gb              = optional(number, null) # null = image default
      storage_account_type = optional(string, "Premium_LRS")
      caching              = optional(string, "ReadWrite")
    }), {})

    # Pre-created managed disks (modules/storage/disk/azure) to attach.
    # The disk itself lives outside this module so it survives VM rebuilds.
    # lun is a plan-time literal and is used as the for_each key — safe even
    # though disk_id is computed.
    data_disks = optional(list(object({
      disk_id = string
      lun     = number
      caching = optional(string, "ReadWrite")
    })), [])
    # NICs are created with count = length(networks) (see main.tf), which only
    # depends on the number of entries — not their values — so these fields can
    # safely be optional() even when subnet_id is computed. The one caveat is
    # network_security_group_id: it feeds a for_each filter for the NSG
    # association, so passing a *computed* NSG id can hit the unknown-value
    # for_each limitation. Leave it null (the default) unless you have a
    # plan-time-known NSG id, or create the NSG in an earlier apply.
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
  })
  description = "VM configuration. os_type must be 'Linux' or 'Windows'. admin_pass is required for Windows. networks[0] is the primary NIC and receives the public IP when create_public_ip = true."

  validation {
    condition     = length(var.vm.networks) > 0
    error_message = "vm.networks must contain at least one entry."
  }
}
