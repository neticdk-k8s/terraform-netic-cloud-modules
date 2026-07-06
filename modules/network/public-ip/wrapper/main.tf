locals {
  is_ovh = var.public_ip.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  public_ip = var.public_ip.ovh
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  public_ip = var.public_ip.azure
}
