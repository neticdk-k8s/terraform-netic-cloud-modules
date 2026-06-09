locals {
  is_ovh = var.public_ip.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  public_ip = {
    name            = var.public_ip.name
    location        = var.public_ip.location
    resource_group  = var.public_ip.resource_group
    prevent_destroy = var.public_ip.prevent_destroy
    tags            = var.public_ip.tags
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  public_ip = {
    name            = var.public_ip.name
    location        = var.public_ip.location
    resource_group  = var.public_ip.resource_group
    prevent_destroy = var.public_ip.prevent_destroy
    tags            = var.public_ip.tags
  }
}
