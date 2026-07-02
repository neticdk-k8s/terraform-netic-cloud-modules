locals {
  is_windows     = lower(var.vm.os_type) == "windows"
  create_ssh_key = var.vm.ssh_public_key == null && !local.is_windows

  # Networks that need a dedicated port: a static IP and/or disabled port
  # security (ip_forwarding) can only be expressed on an explicit port,
  # not on a plain name-based network attachment.
  routed_networks = { for n in var.vm.networks : n.name => n if n.static_ip != null || n.ip_forwarding }

  # Everything else attaches by name (DHCP, port security enabled) as before.
  simple_network_names = [for n in var.vm.networks : n.name if n.static_ip == null && !n.ip_forwarding]

  # Combine networks by name and port-ID into a single list for the dynamic block.
  # create_public_ip prepends Ext-Net (OVH's public internet network)
  networks = concat(
    var.vm.create_public_ip ? [{ name = "Ext-Net", port = null }] : [],
    [for n in local.simple_network_names : { name = n, port = null }],
    [for k, p in openstack_networking_port_v2.routed : { name = null, port = p.id }]
  )
}

# Dedicated port per network that requested a static IP and/or ip_forwarding.
# ip_forwarding = true disables port security entirely (Neutron's anti-spoofing
# *and* security groups) — required for a VM that routes/forwards traffic that
# isn't addressed to its own IP (firewalls, NAT/VPN gateways, etc.).
resource "openstack_networking_port_v2" "routed" {
  for_each = local.routed_networks

  name                  = "${var.vm.name}-${each.key}-port"
  network_id            = each.value.network_id
  port_security_enabled = !each.value.ip_forwarding

  dynamic "fixed_ip" {
    for_each = each.value.static_ip != null ? [1] : []
    content {
      subnet_id  = each.value.subnet_id
      ip_address = each.value.static_ip
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.network_id != null
      error_message = "networks[].network_id must be set when static_ip is set or ip_forwarding is true (a dedicated port has to be created)."
    }
    precondition {
      condition     = each.value.static_ip == null || each.value.subnet_id != null
      error_message = "networks[].subnet_id must be set when static_ip is set."
    }
  }
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
