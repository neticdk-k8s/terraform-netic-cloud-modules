# keyvault/wrapper

Cloud-agnostisk wrapper der opretter en secret-vault: **Azure Key Vault** eller **OVH Cloud Key
Manager-container**. Sæt præcis én af `key_vault.azure` / `key_vault.ovh` — modulet dispatcher til
det rette provider-modul.

Secrets tilføjes bagefter med [`../secret`](../secret)-modulet.

## Brug

### Azure

```hcl
module "keyvault" {
  source = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/wrapper?ref=v0.0.9"

  key_vault = {
    name   = "kv-netic-test"
    region = "denmarkeast" # Azure location / OVH region
    azure = {
      resource_group = "rg-netic-test"
    }
  }
}
```

### OVH

```hcl
module "keyvault" {
  source = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/wrapper?ref=v0.0.9"

  key_vault = {
    name   = "kms-netic-test"
    region = "GRA" # Azure location / OVH region
    ovh = {
      project_id = "<dit OVH project ID>"
    }
  }
}
```

## Output

| Output | Beskrivelse |
|---|---|
| `id` | Vault-ID — bruges som `key_vault_id` (Azure) i secret-modulet |
| `name` | Navn |
| `uri` | Vault URI (null på OVH) |
