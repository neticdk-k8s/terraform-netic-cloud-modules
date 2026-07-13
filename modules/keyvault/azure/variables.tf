variable "key_vault" {
  type = object({
    name           = string
    location       = string
    resource_group = string
    sku_name       = optional(string, "standard") # standard / premium
    tenant_id      = optional(string, null)        # default: den aktuelle client_config-tenant

    # Adgangsmodel:
    #   false (default) = access policies. Hver principal i access_principals får en secret-policy (role ignoreres).
    #   true            = RBAC. Hver principal i access_principals får sin role via role assignment.
    # Den deployende principal tilføjes automatisk i begge modes, så secret-modulet kan skrive.
    rbac_authorization_enabled = optional(bool, false)
    access_principals = optional(list(object({
      principal_id = string
      role         = optional(string, "Key Vault Secrets Officer") # rolle i RBAC-mode; ignoreres i policy-mode
    })), [])

    purge_protection_enabled      = optional(bool, false)
    soft_delete_retention_days    = optional(number, 7)
    public_network_access_enabled = optional(bool, true)
    tags                          = optional(map(string), {})
  })
  description = "Azure Key Vault configuration."
}
