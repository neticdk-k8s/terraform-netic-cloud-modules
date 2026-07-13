locals {
  is_ovh = var.vault.ovh != null
}

module "ovh" {
  count  = local.is_ovh ? 1 : 0
  source = "../ovh"

  ovh_project_id       = var.vault.ovh.project_id
  region               = var.vault.ovh.region
  secret_type          = var.vault.ovh.secret_type
  payload_content_type = var.vault.ovh.payload_content_type
  secrets              = var.secrets
}

module "azure" {
  count  = local.is_ovh ? 0 : 1
  source = "../azure"

  key_vault_id = var.vault.azure.key_vault_id
  content_type = var.vault.azure.content_type
  secrets      = var.secrets
}
