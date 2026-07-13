data "azurerm_client_config" "current" {}

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

  # Uden RBAC: giv den deployende principal adgang til at skrive secrets,
  # så keyvault/secret-modulet virker uden manuel rolletildeling.
  dynamic "access_policy" {
    for_each = var.key_vault.rbac_authorization_enabled ? [] : [1]
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  }
}
