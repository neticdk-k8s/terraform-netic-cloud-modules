# keyvault/ovh

Opretter en **OVH Cloud Key Manager (KMS) container** (`ovh_cloud_key_manager_container`) — det
nærmeste OVH-modstykke til en Azure Key Vault. Kaldes normalt via [`../wrapper`](../wrapper).

> **Bemærk:** OVH-secrets (`ovh_cloud_key_manager_secret` i [`../secret`](../secret)) er
> **projekt/region-scoped** og refererer *ikke* containeren — de kan oprettes uden den. Containeren
> er en valgfri logisk gruppering, som her giver et "vault"-objekt symmetrisk med Azure.

## Input

| Variabel | Beskrivelse |
|---|---|
| `ovh_project_id` | OVH Public Cloud project ID (`service_name`) |
| `key_vault.name` | Navn på containeren |
| `key_vault.region` | KMS-region |
| `key_vault.type` | `GENERIC` (default) / `CERTIFICATE` / `RSA` |
| `key_vault.availability_zone` | Valgfri AZ |

## Output

| Output | Beskrivelse |
|---|---|
| `id` | Container-ID |
| `name` | Navn |
| `uri` | Altid `null` (OVH har ingen vault-URI) |
