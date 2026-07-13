locals {
  is_ovh = var.key_vault.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id = var.key_vault.ovh.project_id

  key_vault = {
    name              = var.key_vault.name
    region            = var.key_vault.region
    type              = var.key_vault.ovh.type
    availability_zone = var.key_vault.ovh.availability_zone
  }
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  key_vault = {
    name                          = var.key_vault.name
    location                      = var.key_vault.region
    resource_group                = var.key_vault.azure.resource_group
    sku_name                      = var.key_vault.azure.sku_name
    tenant_id                     = var.key_vault.azure.tenant_id
    rbac_authorization_enabled    = var.key_vault.azure.rbac_authorization_enabled
    purge_protection_enabled      = var.key_vault.azure.purge_protection_enabled
    soft_delete_retention_days    = var.key_vault.azure.soft_delete_retention_days
    public_network_access_enabled = var.key_vault.azure.public_network_access_enabled
    tags                          = var.key_vault.azure.tags
  }
}
