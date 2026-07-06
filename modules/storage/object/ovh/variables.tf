variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "storage" {
  type = object({
    name             = string
    region           = optional(string, "GRA")
    versioning       = optional(string, "enabled") # 'enabled' or 'disabled'
    encryption_sse   = optional(string, "AES256")
    object_lock_days = optional(number, 0) # 0 = disabled
  })
  description = "Object storage bucket configuration"
}
