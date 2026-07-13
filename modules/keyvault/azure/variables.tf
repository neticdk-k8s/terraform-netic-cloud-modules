variable "key_vault" {
  type = object({
    name           = string
    location       = string
    resource_group = string
    sku_name       = optional(string, "standard") # standard / premium
    tenant_id      = optional(string, null)        # default: den aktuelle client_config-tenant

    # RBAC vs. access policies. Med RBAC = true skal den principal der kører
    # Terraform have rollen "Key Vault Secrets Officer" for at kunne skrive secrets.
    # Med false opretter modulet automatisk en access policy til den aktuelle deployer.
    rbac_authorization_enabled    = optional(bool, false)
    purge_protection_enabled      = optional(bool, false)
    soft_delete_retention_days    = optional(number, 7)
    public_network_access_enabled = optional(bool, true)
    tags                          = optional(map(string), {})
  })
  description = "Azure Key Vault configuration."
}
