variable "ovh_project_id" {
  type        = string
  description = "OVH Public Cloud project ID (service_name)."
}

variable "key_vault" {
  type = object({
    name              = string
    region            = string
    type              = optional(string, "GENERIC") # GENERIC / CERTIFICATE / RSA
    availability_zone = optional(string, null)
  })
  description = "OVH Cloud Key Manager (KMS) container — logisk gruppering af secrets."

  validation {
    condition     = contains(["GENERIC", "CERTIFICATE", "RSA"], var.key_vault.type)
    error_message = "key_vault.type skal være GENERIC, CERTIFICATE eller RSA."
  }
}
