# keyvault/wrapper

Cloud-agnostisk wrapper der opretter en secret-vault: **Azure Key Vault** eller **OVHcloud KMS
(OKMS)**. Sæt præcis én af `key_vault.azure` / `key_vault.ovh` — modulet dispatcher til det rette
provider-modul.

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

**Azure — RBAC-mode i stedet for access policies:**

```hcl
    azure = {
      resource_group             = "rg-netic-test"
      rbac_authorization_enabled = true
      access_principals = [
        { principal_id = "11111111-1111-1111-1111-111111111111" },                                  # role → default (Secrets Officer)
        { principal_id = "22222222-2222-2222-2222-222222222222", role = "Key Vault Administrator" }, # egen rolle
      ]
    }
```

Den deployende principal tilføjes automatisk i begge modes. I policy-mode (default) bliver
`access_principals` i stedet til access policies (rollen ignoreres).

### OVH

```hcl
module "keyvault" {
  source = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/wrapper?ref=v0.0.9"

  key_vault = {
    name   = "kms-netic-test"
    region = "eu-west-gra" # OKMS-region
    ovh = {
      subsidiary = "IE" # OVH subsidiary — skal matche kontoen
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
