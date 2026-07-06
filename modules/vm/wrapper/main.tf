locals {
  is_ovh = var.vm.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id = try(var.vm.ovh.project_id, "")

  vm = {
    name             = var.vm.name
    size             = var.vm.size
    image_name       = try(var.vm.ovh.image_name, "")
    os_type          = var.vm.os_type
    ssh_public_key   = var.vm.ssh_public_key
    admin_pass       = var.vm.admin_pass
    resource_group   = var.vm.resource_group
    create_public_ip = var.vm.create_public_ip
    network_names    = try(var.vm.ovh.network_names, [])
    port_ids         = try(var.vm.ovh.port_ids, [])
    disk_ids         = try(var.vm.ovh.disk_ids, [])
    os_disk          = try(var.vm.ovh.os_disk, null)
    power_state      = try(var.vm.ovh.power_state, "active")
    user_data        = var.vm.user_data
    security_groups  = try(var.vm.ovh.security_groups, ["default"])
    tags             = var.vm.tags
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  vm = {
    name             = var.vm.name
    size             = var.vm.size
    location         = var.vm.location
    resource_group   = var.vm.resource_group
    os_type          = var.vm.os_type
    admin_username   = try(var.vm.azure.admin_username, "azureuser")
    zone             = try(var.vm.azure.zone, null)
    boot_diagnostics = try(var.vm.azure.boot_diagnostics, false)
    os_disk          = try(var.vm.azure.os_disk, {})
    data_disks       = try(var.vm.azure.data_disks, [])
    admin_pass       = var.vm.admin_pass
    ssh_public_key   = var.vm.ssh_public_key
    networks         = try(var.vm.azure.networks, [])
    create_public_ip = var.vm.create_public_ip
    user_data        = var.vm.user_data
    image            = try(var.vm.azure.image, { publisher = "", offer = "", sku = "", version = "latest" })
    tags             = var.vm.tags
  }
}
