# OVH Cloud Key Manager secret. Projekt/region-scoped — kræver ikke en container.
# payload er write-only og returneres aldrig af API'et.
resource "ovh_cloud_key_manager_secret" "this" {
  # Kun secret-navnene bruges som for_each-nøgler (ikke-følsomme); værdien slås op sensitivt.
  for_each = nonsensitive(toset(keys(var.secrets)))

  service_name         = var.ovh_project_id
  region               = var.region
  name                 = each.key
  payload              = var.secrets[each.key]
  payload_content_type = var.payload_content_type
  secret_type          = var.secret_type
}
