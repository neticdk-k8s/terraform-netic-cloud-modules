# keyvault/secret/azure

Tilføjer én eller flere secrets (`azurerm_key_vault_secret`) til en eksisterende Azure Key Vault.
Kaldes normalt via [`../wrapper`](../wrapper).

## Input

| Variabel | Beskrivelse |
|---|---|
| `key_vault_id` | Resource ID på vaulten (output `id` fra keyvault-modulet) |
| `secrets` | Map `navn → værdi`, fx `{ login = "kodeord" }` (sensitive) |
| `content_type` | Valgfri content-type, fx `"text/plain"` |

## Output

| Output | Beskrivelse |
|---|---|
| `secret_ids` | Map: navn → versioned secret-ID |
| `secret_versionless_ids` | Map: navn → versionless ID (nyeste version) |
