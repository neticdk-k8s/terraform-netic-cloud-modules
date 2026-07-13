locals {
  is_ovh = var.vault.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  okms_id = var.vault.ovh.okms_id
  secrets = var.secrets
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  key_vault_id = var.vault.azure.key_vault_id
  content_type = var.vault.azure.content_type
  secrets      = var.secrets
}
