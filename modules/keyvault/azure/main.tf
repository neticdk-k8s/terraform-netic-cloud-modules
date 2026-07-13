data "azurerm_client_config" "current" {}

locals {
  # Den deployende principal tilføjes altid (så keyvault/secret-modulet kan skrive).
  deployer = { principal_id = data.azurerm_client_config.current.object_id, role = "Key Vault Secrets Officer" }

  principals = distinct(concat(var.key_vault.access_principals, [local.deployer]))

  # RBAC-mode: én role assignment pr. (principal, role). Nøglen tillader samme
  # principal med flere roller. Tomt i policy-mode.
  role_assignments = var.key_vault.rbac_authorization_enabled ? {
    for p in local.principals : "${p.principal_id}|${p.role}" => p
  } : {}

  # Policy-mode: én access policy pr. principal (role ignoreres). Tomt i RBAC-mode.
  policy_object_ids = var.key_vault.rbac_authorization_enabled ? toset([]) : toset([
    for p in local.principals : p.principal_id
  ])
}

resource "azurerm_key_vault" "this" {
  name                = var.key_vault.name
  location            = var.key_vault.location
  resource_group_name = var.key_vault.resource_group
  tenant_id           = coalesce(var.key_vault.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name            = var.key_vault.sku_name

  rbac_authorization_enabled    = var.key_vault.rbac_authorization_enabled
  purge_protection_enabled      = var.key_vault.purge_protection_enabled
  soft_delete_retention_days    = var.key_vault.soft_delete_retention_days
  public_network_access_enabled = var.key_vault.public_network_access_enabled

  tags = var.key_vault.tags

  # Policy-mode (RBAC slået fra): én access policy pr. principal.
  dynamic "access_policy" {
    for_each = local.policy_object_ids
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = access_policy.value
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  }
}

# RBAC-mode (RBAC slået til): tildel hver principal sin role på vaulten.
resource "azurerm_role_assignment" "this" {
  for_each = local.role_assignments

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
