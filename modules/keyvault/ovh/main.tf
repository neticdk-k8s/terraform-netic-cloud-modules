# OVH Cloud Key Manager (KMS) container.
# NB: OVH-secrets (ovh_cloud_key_manager_secret) er projekt/region-scoped og kræver
# IKKE en container — containeren er en valgfri logisk gruppering. Den giver et
# "vault"-objekt symmetrisk med Azure Key Vault.
resource "ovh_cloud_key_manager_container" "this" {
  service_name      = var.ovh_project_id
  name              = var.key_vault.name
  region            = var.key_vault.region
  type              = var.key_vault.type
  availability_zone = var.key_vault.availability_zone
}
