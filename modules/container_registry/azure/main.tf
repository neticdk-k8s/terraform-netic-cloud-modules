resource "azurerm_container_registry" "registry" {
  count               = var.container_registry.deploy ? 1 : 0
  name                = var.container_registry.name
  resource_group_name = var.container_registry.resource_group
  location            = var.container_registry.location
  sku                 = var.container_registry.sku
  admin_enabled       = true

  dynamic "network_rule_set" {
    for_each = var.container_registry.sku == "Premium" && length(var.ip_restrictions) > 0 ? [1] : []
    content {
      default_action = "Deny"
      dynamic "ip_rule" {
        for_each = var.ip_restrictions
        content {
          action   = "Allow"
          ip_range = ip_rule.value.ip_block
        }
      }
    }
  }

  tags = var.container_registry.tags
}

# Shared read/write scope map used by all tokens
resource "azurerm_container_registry_scope_map" "rw" {
  count                   = var.container_registry.deploy && length(var.registry_users) > 0 ? 1 : 0
  name                    = "readwrite"
  container_registry_name = azurerm_container_registry.registry[0].name
  resource_group_name     = var.container_registry.resource_group
  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read",
    "repositories/*/metadata/write",
  ]
}

resource "azurerm_container_registry_token" "user" {
  for_each = var.container_registry.deploy ? { for u in var.registry_users : u.login => u } : {}

  name                    = each.value.login
  container_registry_name = azurerm_container_registry.registry[0].name
  resource_group_name     = var.container_registry.resource_group
  scope_map_id            = azurerm_container_registry_scope_map.rw[0].id
}

resource "azurerm_container_registry_token_password" "user_password" {
  for_each = var.container_registry.deploy ? { for u in var.registry_users : u.login => u } : {}

  container_registry_token_id = azurerm_container_registry_token.user[each.key].id
  password1 {}
}
