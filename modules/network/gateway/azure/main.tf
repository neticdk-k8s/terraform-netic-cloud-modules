resource "azurerm_nat_gateway" "gw" {
  name                    = var.gateway.name
  location                = var.gateway.location
  resource_group_name     = var.gateway.resource_group
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.gateway.idle_timeout_in_minutes
  tags                    = var.gateway.tags
}

resource "azurerm_nat_gateway_public_ip_association" "gw_pip" {
  nat_gateway_id       = azurerm_nat_gateway.gw.id
  public_ip_address_id = var.gateway.public_ip_id
}

# Keyed by list index (statically known) rather than by subnet ID: the IDs come
# from other resources/modules and may be unknown at plan time, which for_each
# cannot use as keys.
resource "azurerm_subnet_nat_gateway_association" "gw_subnet" {
  for_each = { for idx, sid in var.gateway.subnet_ids : tostring(idx) => sid }

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.gw.id
}
