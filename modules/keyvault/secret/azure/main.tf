resource "azurerm_key_vault_secret" "this" {
  # Kun secret-navnene bruges som for_each-nøgler (ikke-følsomme); værdien slås op sensitivt.
  for_each = nonsensitive(toset(keys(var.secrets)))

  name         = each.key
  value        = var.secrets[each.key]
  key_vault_id = var.key_vault_id
  content_type = var.content_type
}
