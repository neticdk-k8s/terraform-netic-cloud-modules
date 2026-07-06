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

# One NIC per entry in vm.networks. networks[0] is always the primary NIC
# (azurerm attaches network_interface_ids in order, first = primary) and is
# the one that receives the public IP.
#
# ip_forwarding = true sets ip_forwarding_enabled on that NIC — required for a
# VM that routes/forwards traffic not addressed to its own IP (firewall, NAT
# gateway, VPN endpoint). Unlike OVH's port_security_enabled = false, this does
# NOT disable NSG enforcement — attach network_security_group_id (or associate
# the subnet's NSG separately) to actually permit the forwarded traffic.
resource "azurerm_network_interface" "nic" {
  count               = length(var.vm.networks)
  name                = "${var.vm.name}-nic-${count.index}"
  location            = var.vm.location
  resource_group_name = var.vm.resource_group
  tags                = var.vm.tags

  ip_forwarding_enabled = var.vm.networks[count.index].ip_forwarding

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm.networks[count.index].subnet_id
    private_ip_address_allocation = var.vm.networks[count.index].static_ip != null ? "Static" : "Dynamic"
    private_ip_address            = var.vm.networks[count.index].static_ip
    public_ip_address_id          = (var.vm.create_public_ip && count.index == 0) ? azurerm_public_ip.public_ip[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  for_each = {
    for idx, n in var.vm.networks : idx => n
    if n.network_security_group_id != null
  }

  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = each.value.network_security_group_id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = local.is_windows ? 0 : 1
  name                = var.vm.name
  location            = var.vm.location
  resource_group_name = var.vm.resource_group
  size                = var.vm.size
  admin_username      = var.vm.admin_username
  zone                = var.vm.zone

  tags                  = var.vm.tags
  network_interface_ids = azurerm_network_interface.nic[*].id

  admin_ssh_key {
    username   = var.vm.admin_username
    public_key = local.create_ssh_key ? trimspace(tls_private_key.ssh_key[0].public_key_openssh) : var.vm.ssh_public_key
  }

  os_disk {
    caching              = var.vm.os_disk.caching
    storage_account_type = var.vm.os_disk.storage_account_type
    disk_size_gb         = var.vm.os_disk.size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = var.vm.boot_diagnostics ? [1] : []
    content {} # empty block = managed storage account
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
  zone                = var.vm.zone
  tags                = var.vm.tags

  network_interface_ids = azurerm_network_interface.nic[*].id

  os_disk {
    caching              = var.vm.os_disk.caching
    storage_account_type = var.vm.os_disk.storage_account_type
    disk_size_gb         = var.vm.os_disk.size_gb
  }

  dynamic "boot_diagnostics" {
    for_each = var.vm.boot_diagnostics ? [1] : []
    content {} # empty block = managed storage account
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

######################################
###          Data disks            ###
######################################

# Attach pre-created managed disks (modules/storage/disk/azure). Keyed on lun
# (a plan-time literal), so computed disk IDs never become for_each keys.
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for d in var.vm.data_disks : d.lun => d }

  managed_disk_id    = each.value.disk_id
  virtual_machine_id = local.is_windows ? azurerm_windows_virtual_machine.vm[0].id : azurerm_linux_virtual_machine.vm[0].id
  lun                = each.value.lun
  caching            = each.value.caching
}
