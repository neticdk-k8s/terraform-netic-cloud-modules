# keyvault/azure

Opretter en **Azure Key Vault** (`azurerm_key_vault`). Kaldes normalt via
[`../wrapper`](../wrapper), ikke direkte.

Uden RBAC (`rbac_authorization_enabled = false`, default) får den principal der kører Terraform
automatisk en access policy med secret-rettigheder, så [`../secret`](../secret) kan skrive med det
samme. Med RBAC slået til skal principalen i stedet tildeles rollen **Key Vault Secrets Officer**.

## Input

`key_vault` — objekt: `name`, `location`, `resource_group` (required); `sku_name`, `tenant_id`,
`rbac_authorization_enabled`, `purge_protection_enabled`, `soft_delete_retention_days`,
`public_network_access_enabled`, `tags` (optional).

## Output

| Output | Beskrivelse |
|---|---|
| `id` | Key Vault resource ID — bruges som `key_vault_id` i secret-modulet |
| `name` | Navn på vaulten |
| `uri` | Vault URI |
