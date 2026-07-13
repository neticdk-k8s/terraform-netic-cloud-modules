# keyvault/secret/ovh

Tilføjer secrets (`ovh_cloud_key_manager_secret`) til OVH Cloud Key Manager (KMS). Secrets er
**projekt/region-scoped** og kræver ikke en container. Kaldes normalt via [`../wrapper`](../wrapper).

## Input

| Variabel | Beskrivelse |
|---|---|
| `ovh_project_id` | OVH project ID (`service_name`) |
| `region` | KMS-region (skal matche vaulten) |
| `secrets` | Map `navn → værdi`, fx `{ login = "kodeord" }` (sensitive) |
| `secret_type` | `OPAQUE` (default) / SYMMETRIC / PUBLIC / PRIVATE / PASSPHRASE / CERTIFICATE |
| `payload_content_type` | `TEXT_PLAIN` (default, klartekst) / `APPLICATION_OCTET_STREAM` (kræver base64) |

> `payload` er write-only i OVH's API og returneres aldrig — Terraform kan derfor ikke drift-detektere
> selve værdien. For et login/kodeord passer `secret_type = OPAQUE` (eller `PASSPHRASE`) med
> `TEXT_PLAIN`.

## Output

| Output | Beskrivelse |
|---|---|
| `secret_ids` | Map: navn → secret-ID |
