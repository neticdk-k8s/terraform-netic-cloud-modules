variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "vm" {
  type = object({
    name             = string
    size             = string
    image_name       = string
    os_type          = optional(string, "Linux")
    resource_group   = string # only used as a metadata tag on OVH — grouping convention, not a cloud resource
    create_public_ip = optional(bool, false)
    ssh_public_key   = optional(string, null)
    admin_pass       = optional(string, null)
    network_names    = optional(list(string), [])
    port_ids         = optional(list(string), [])
    disk_ids         = optional(list(string), []) # pre-created volumes (modules/storage/disk/ovh) to attach as data disks

    # Boot from a volume with chosen size/type instead of the flavor's fixed
    # local disk. Requires a *flex* flavor (e.g. "b2-7-flex") to make sense —
    # non-flex flavors already include (and bill) their full local disk.
    os_disk = optional(object({
      size_gb     = number
      volume_type = optional(string, null) # classic | high-speed | high-speed-gen2, null = cloud default
    }), null)
    power_state     = optional(string, "active")
    user_data       = optional(string, null)
    security_groups = optional(list(string), ["default"])
    tags            = optional(map(string), {})
  })

  validation {
    condition     = !contains(var.vm.network_names, "Ext-Net")
    error_message = "Ext-Net must not be in network_names — set create_public_ip = true instead."
  }
}
