# keyvault/azure

Opretter en **Azure Key Vault** (`azurerm_key_vault`). Kaldes normalt via
[`../wrapper`](../wrapper), ikke direkte.

Modulet understøtter **to adgangsmodeller**, styret af `rbac_authorization_enabled`:

- **Policy-mode** (`false`, default) — hver principal i `access_principals` får en `access_policy`
  med secret-rettigheder (`role` ignoreres).
- **RBAC-mode** (`true`) — hver principal i `access_principals` får sin `role`
  (default `Key Vault Secrets Officer`) via `azurerm_role_assignment` på vaulten. Samme principal kan
  stå flere gange med forskellige roller.

I begge modes tilføjes den **deployende principal automatisk**, så [`../secret`](../secret) kan skrive
med det samme.

## Input

`key_vault` — objekt:

| Felt | Beskrivelse |
|---|---|
| `name`, `location`, `resource_group` | Required |
| `rbac_authorization_enabled` | `false` = access policies, `true` = RBAC-roller |
| `access_principals` | Liste af `{ principal_id, role }` — GUID + rolle (role default `Key Vault Secrets Officer`, kun brugt i RBAC-mode) |
| `sku_name`, `tenant_id`, `purge_protection_enabled`, `soft_delete_retention_days`, `public_network_access_enabled`, `tags` | Optional |

## Output

| Output | Beskrivelse |
|---|---|
| `id` | Key Vault resource ID — bruges som `key_vault_id` i secret-modulet |
| `name` | Navn på vaulten |
| `uri` | Vault URI |
