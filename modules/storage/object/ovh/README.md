# Object Storage — OVH

Opretter en OVH S3-kompatibel object storage bucket med SSE-kryptering og valgfri object lock.

## Usage

```hcl
module "storage" {
  source = "./modules/storage/object/ovh"

  ovh_project_id = var.ovh_project_id
  name           = "my-bucket"
  region         = "GRA"
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ovh_project_id` | `string` | — | OVH Cloud project ID / service name |
| `name` | `string` | — | Bucket-navn |
| `region` | `string` | `"GRA"` | OVH-region (f.eks. `"GRA"`, `"SBG"`) |
| `versioning` | `string` | `"enabled"` | `"enabled"` eller `"disabled"` |
| `encryption_sse` | `string` | `"AES256"` | SSE-algoritme |
| `object_lock_days` | `number` | `0` | Retention i dage (0 = deaktiveret) |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på bucket'en |
| `storage_name` | Navn på bucket'en |
| `storage_region` | Region for bucket'en |
| `connection_string` | `null` — brug S3-kompatibelt endpoint i stedet |
