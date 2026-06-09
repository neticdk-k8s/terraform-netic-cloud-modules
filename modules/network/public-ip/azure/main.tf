resource "azurerm_public_ip" "pip" {
  count               = var.public_ip.prevent_destroy ? 0 : 1
  name                = var.public_ip.name
  location            = var.public_ip.location
  resource_group_name = var.public_ip.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.public_ip.tags
}

resource "azurerm_public_ip" "pip_protected" {
  count               = var.public_ip.prevent_destroy ? 1 : 0
  name                = var.public_ip.name
  location            = var.public_ip.location
  resource_group_name = var.public_ip.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.public_ip.tags

  lifecycle {
    prevent_destroy = true
  }
}
