locals {
  is_windows     = lower(var.vm.os_type) == "windows"
  create_ssh_key = !local.is_windows && var.vm.ssh_public_key == null
}

resource "tls_private_key" "ssh_key" {
  count     = local.create_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.vm.create_public_ip ? 1 : 0
  name                = "${var.vm.name}-pip"
  location            = var.vm.location
  resource_group_name = var.vm.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.vm.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm.name}-nic"
  location            = var.vm.location
  resource_group_name = var.vm.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.vm.create_public_ip ? azurerm_public_ip.public_ip[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = local.is_windows ? 0 : 1
  name                = var.vm.name
  location            = var.vm.location
  resource_group_name = var.vm.resource_group
  size                = var.vm.size
  admin_username      = var.vm.admin_username

  tags                  = var.vm.tags
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.vm.admin_username
    public_key = local.create_ssh_key ? trimspace(tls_private_key.ssh_key[0].public_key_openssh) : var.vm.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.vm.image.publisher
    offer     = var.vm.image.offer
    sku       = var.vm.image.sku
    version   = var.vm.image.version
  }

  # user_data must be base64-encoded in Azure
  user_data = var.vm.user_data != null ? base64encode(var.vm.user_data) : null

  lifecycle {
    ignore_changes = [source_image_reference]
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  count               = local.is_windows ? 1 : 0
  name                = var.vm.name
  location            = var.vm.location
  resource_group_name = var.vm.resource_group
  size                = var.vm.size
  admin_username      = var.vm.admin_username
  admin_password      = var.vm.admin_pass
  tags                = var.vm.tags

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.vm.image.publisher
    offer     = var.vm.image.offer
    sku       = var.vm.image.sku
    version   = var.vm.image.version
  }

  custom_data = var.vm.user_data != null ? base64encode(var.vm.user_data) : null

  lifecycle {
    ignore_changes = [source_image_reference]
    precondition {
      condition     = var.vm.admin_pass != null
      error_message = "admin_pass must be set for Windows VMs."
    }
  }
}
