# keyvault/secret/wrapper

Cloud-agnostisk wrapper der tilføjer secrets (fx `login = kodeord`) til en vault oprettet med
[`../../wrapper`](../../wrapper). Sæt præcis én af `vault.azure` / `vault.ovh`.

## Brug

### Azure — læg secrets i en Key Vault

```hcl
module "keyvault" {
  source    = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/wrapper?ref=v0.0.9"
  key_vault = {
    name  = "kv-netic-test"
    azure = { location = "denmarkeast", resource_group = "rg-netic-test" }
  }
}

module "secrets" {
  source  = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/secret/wrapper?ref=v0.0.9"
  secrets = { login = "kodeord" }
  vault   = { azure = { key_vault_id = module.keyvault.id } }
}
```

### OVH — læg secrets i Cloud Key Manager

```hcl
module "secrets" {
  source  = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/keyvault/secret/wrapper?ref=v0.0.9"
  secrets = { login = "kodeord" }
  vault = {
    ovh = {
      project_id = "<dit OVH project ID>"
      region     = "GRA"
    }
  }
}
```

> OVH-secrets er projekt/region-scoped og kræver ikke en container — `keyvault/wrapper` er derfor
> valgfri på OVH (kun nødvendig hvis du vil gruppere secrets i en container).

## Output

| Output | Beskrivelse |
|---|---|
| `secret_ids` | Map: secret-navn → resource ID |
