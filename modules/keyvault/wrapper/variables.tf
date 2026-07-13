variable "key_vault" {
  type = object({
    name   = string
    region = string # Azure location / OVH region

    ovh = optional(object({
      project_id        = string
      type              = optional(string, "GENERIC")
      availability_zone = optional(string, null)
    }), null)

    azure = optional(object({
      resource_group                = string
      sku_name                      = optional(string, "standard")
      tenant_id                     = optional(string, null)
      rbac_authorization_enabled    = optional(bool, false)
      purge_protection_enabled      = optional(bool, false)
      soft_delete_retention_days    = optional(number, 7)
      public_network_access_enabled = optional(bool, true)
      tags                          = optional(map(string), {})
    }), null)
  })
  description = "Key Vault configuration. Sæt præcis én af key_vault.ovh eller key_vault.azure."

  validation {
    condition     = (var.key_vault.ovh != null) != (var.key_vault.azure != null)
    error_message = "Præcis én af key_vault.ovh eller key_vault.azure skal være sat."
  }
}
