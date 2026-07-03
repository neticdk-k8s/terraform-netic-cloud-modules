variable "storage" {
  type = object({
    name             = string # 3-24 chars, lowercase alphanumeric, globally unique
    resource_group   = string
    location         = string
    replication_type = optional(string, "LRS")
    versioning       = optional(bool, true)
    retention_days   = optional(number, 7) # soft-delete days, 0 = disabled
    container_name   = optional(string, "data")
    tags             = optional(map(string), {})
  })
  description = "Storage account + blob container configuration"
}
