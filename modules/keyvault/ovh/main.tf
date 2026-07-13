# OVHcloud KMS (OKMS) — Key Management / Secret Manager.
# Konto-scoped: identificeres af ovh_subsidiary + region (IKKE et project_id).
resource "ovh_okms" "this" {
  display_name   = var.key_vault.name
  region         = var.key_vault.region
  ovh_subsidiary = var.key_vault.subsidiary
}
