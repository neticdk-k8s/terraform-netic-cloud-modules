# Object Storage — OVH

Opretter en OVH S3-kompatibel object storage bucket med SSE-kryptering og valgfri object lock.

## Usage

```hcl
module "storage" {
  source = "./modules/storage/object/ovh"

  ovh_project_id = var.ovh_project_id

  storage = {
    name   = "my-bucket"
    region = "GRA"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ovh_project_id` | `string` | — | OVH Cloud project ID / service name |
| `storage.name` | `string` | — | Bucket-navn |
| `storage.region` | `string` | `"GRA"` | OVH-region (f.eks. `"GRA"`, `"SBG"`) |
| `storage.versioning` | `string` | `"enabled"` | `"enabled"` eller `"disabled"` |
| `storage.encryption_sse` | `string` | `"AES256"` | SSE-algoritme |
| `storage.object_lock_days` | `number` | `0` | Retention i dage (0 = deaktiveret) |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på bucket'en |
| `storage_name` | Navn på bucket'en |
| `storage_region` | Region for bucket'en |
| `connection_string` | `null` — brug S3-kompatibelt endpoint i stedet |
