variable "disk" {
  type = object({
    name                 = string
    size_gb              = number
    resource_group       = string
    location             = string
    storage_account_type = optional(string, "Premium_LRS")
    zone                 = optional(string, null) # must match the VM's zone if the VM is zonal
    tags                 = optional(map(string), {})
  })
  description = "Managed data disk configuration"
}
