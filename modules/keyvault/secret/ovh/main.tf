# OVHcloud OKMS secret. Hvert secret-navn bliver en path i OKMS med versioneret data.
# version.data er write-only; første apply opretter version 1.
resource "ovh_okms_secret" "this" {
  # Kun secret-navnene (paths) bruges som for_each-nøgler (ikke-følsomme); værdien slås op sensitivt.
  for_each = nonsensitive(toset(keys(var.secrets)))

  okms_id = var.okms_id
  path    = each.key

  # OKMS kræver at data er JSON key-value. Værdien lægges under nøglen "value",
  # så path'en (secret-navnet) holder ét felt: {"value": "<værdi>"}.
  version = {
    data = jsonencode({ value = var.secrets[each.key] })
  }
}
