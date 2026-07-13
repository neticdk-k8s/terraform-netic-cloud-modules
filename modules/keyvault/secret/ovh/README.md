# keyvault/secret/ovh

Tilføjer secrets (`ovh_okms_secret`) til en OKMS-instans. Hvert secret-navn bliver en **path** med
versioneret data. Kaldes normalt via [`../wrapper`](../wrapper).

## Input

| Variabel | Beskrivelse |
|---|---|
| `okms_id` | OKMS-instansens ID (output `id` fra keyvault-modulet) |
| `secrets` | Map `navn → værdi`, fx `{ login = "kodeord" }` (sensitive) — navnet bruges som path |

> OKMS kræver at `version.data` er **JSON key-value**, så værdien gemmes som `{"value": "<værdi>"}`
> på path'en — læs den tilbage under nøglen `value`. `version.data` er write-only i OVH's API; første
> apply opretter version 1. `ovh_okms_secret` har intet selvstændigt `id` — det identificeres af
> `okms_id` + `path`.

## Output

| Output | Beskrivelse |
|---|---|
| `secret_ids` | Map: navn → path i OKMS |
