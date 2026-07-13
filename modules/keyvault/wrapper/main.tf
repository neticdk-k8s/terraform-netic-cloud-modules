locals {
  is_ovh = var.key_vault.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  key_vault = {
    name       = var.key_vault.name
    region     = var.key_vault.region
    subsidiary = var.key_vault.ovh.subsidiary
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
    access_principals             = var.key_vault.azure.access_principals
    purge_protection_enabled      = var.key_vault.azure.purge_protection_enabled
    soft_delete_retention_days    = var.key_vault.azure.soft_delete_retention_days
    public_network_access_enabled = var.key_vault.azure.public_network_access_enabled
    tags                          = var.key_vault.azure.tags
  }
}
