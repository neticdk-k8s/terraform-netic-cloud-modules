resource "azurerm_virtual_network" "vnet" {
  name                = var.network.name
  location            = var.network.location
  resource_group_name = var.network.resource_group
  address_space       = var.network.address_space
  tags                = var.network.tags
}

resource "azurerm_subnet" "subnet" {
  for_each = var.network.subnets

  name                 = each.key
  resource_group_name  = var.network.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_network_security_group" "nsg" {
  for_each = var.network.create_default_nsgs ? var.network.subnets : {}

  name                = "${var.network.name}-${each.key}-nsg"
  location            = var.network.location
  resource_group_name = var.network.resource_group
  tags                = var.network.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = var.network.create_default_nsgs ? var.network.subnets : {}

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
