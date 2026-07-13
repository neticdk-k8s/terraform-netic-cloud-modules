# keyvault/ovh

Opretter en **OVHcloud KMS (OKMS)** instans (`ovh_okms`) — OVH's Key Management / Secret Manager, det
nærmeste modstykke til en Azure Key Vault. Kaldes normalt via [`../wrapper`](../wrapper).

> **Konto-scoped:** OKMS bestilles på kontoen ud fra `ovh_subsidiary` + `region` — ikke et
> Public Cloud `project_id`. Secrets tilføjes med [`../secret`](../secret) via instansens `id` (okms_id).

## Input

| Variabel | Beskrivelse |
|---|---|
| `key_vault.name` | Display-navn på OKMS-instansen |
| `key_vault.region` | OKMS-region, fx `eu-west-gra` |
| `key_vault.subsidiary` | OVH subsidiary (FR / GB / DE / IE / …) — skal matche kontoen |

## Output

| Output | Beskrivelse |
|---|---|
| `id` | OKMS-instansens ID (okms_id) — input til secret-modulet |
| `name` | Display-navn |
| `uri` | REST-endpoint |
