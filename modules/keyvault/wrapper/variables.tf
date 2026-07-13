variable "key_vault" {
  type = object({
    name   = string
    region = string # Azure location / OVH region

    ovh = optional(object({
      subsidiary = string # OVH subsidiary (FR / GB / DE / IE / ...) — OKMS er konto-scoped
    }), null)

    azure = optional(object({
      resource_group                = string
      sku_name                      = optional(string, "standard")
      tenant_id                     = optional(string, null)
      rbac_authorization_enabled = optional(bool, false)
      access_principals = optional(list(object({
        principal_id = string
        role         = optional(string, "Key Vault Secrets Officer")
      })), [])
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
