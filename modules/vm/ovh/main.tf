locals {
  is_windows     = lower(var.vm.os_type) == "windows"
  create_ssh_key = var.vm.ssh_public_key == null && !local.is_windows

  # Combine networks by name and port-ID into a single list for the dynamic block.
  # - network_names: plain name attach (DHCP, port security enabled)
  # - port_ids:      pre-created ports (e.g. from modules/network/port/ovh with
  #                  port security disabled for firewall/router/VPN VMs)
  # create_public_ip prepends Ext-Net (OVH's public internet network)
  networks = concat(
    var.vm.create_public_ip ? [{ name = "Ext-Net", port = null }] : [],
    [for n in var.vm.network_names : { name = n, port = null }],
    [for p in var.vm.port_ids : { name = null, port = p }]
  )
}

######################################
###          SSH Key Section       ###
######################################

resource "tls_private_key" "ssh_key" {
  count     = local.create_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ovh_cloud_project_ssh_key" "default" {
  count        = local.is_windows ? 0 : 1
  service_name = var.ovh_project_id
  name         = "${var.vm.name}-key"
  public_key   = local.create_ssh_key ? trimspace(tls_private_key.ssh_key[0].public_key_openssh) : trimspace(var.vm.ssh_public_key)
}

# openstack_compute_keypair_v2 is required so the compute API can find the key
# (region-scoped). ovh_cloud_project_ssh_key is only visible in the OVH management plane.
resource "openstack_compute_keypair_v2" "default" {
  count      = local.is_windows ? 0 : 1
  name       = "${var.vm.name}-key"
  public_key = local.create_ssh_key ? trimspace(tls_private_key.ssh_key[0].public_key_openssh) : trimspace(var.vm.ssh_public_key)
}


######################################
###          Generate VMs          ###
######################################

# Linux VM
resource "openstack_compute_instance_v2" "VMLinux" {
  count           = local.is_windows ? 0 : 1
  name            = var.vm.name
  flavor_name     = var.vm.size
  image_name      = var.vm.image_name
  key_pair        = openstack_compute_keypair_v2.default[0].name
  security_groups = var.vm.security_groups
  power_state     = var.vm.power_state
  user_data       = var.vm.user_data
  metadata        = merge(var.vm.tags, { resource_group = var.vm.resource_group })

  dynamic "network" {
    for_each = local.networks
    content {
      name = network.value.name
      port = network.value.port
    }
  }

  lifecycle {
    ignore_changes = [image_name]
    precondition {
      condition     = !local.is_windows || var.vm.admin_pass != null
      error_message = "admin_pass must be set for Windows VMs."
    }
  }

  depends_on = [openstack_compute_keypair_v2.default]
}

# Windows VM
resource "openstack_compute_instance_v2" "VMWindows" {
  count           = local.is_windows ? 1 : 0
  name            = var.vm.name
  flavor_name     = var.vm.size
  image_name      = var.vm.image_name
  admin_pass      = var.vm.admin_pass
  security_groups = var.vm.security_groups
  power_state     = var.vm.power_state
  metadata        = merge(var.vm.tags, { resource_group = var.vm.resource_group })

  dynamic "network" {
    for_each = local.networks
    content {
      name = network.value.name
      port = network.value.port
    }
  }

  lifecycle {
    ignore_changes = [image_name]
    precondition {
      condition     = var.vm.admin_pass != null
      error_message = "admin_pass must be set for Windows VMs."
    }
  }
}
