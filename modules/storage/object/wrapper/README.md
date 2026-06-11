# Object Storage — Wrapper

Fælles indgangspunkt til at oprette object storage på enten **Azure** (Blob Storage) eller **OVH** (S3-kompatibel bucket).

Provider vælges ved at sætte præcis ét af `storage.ovh` eller `storage.azure`.

## Usage

### OVH

```hcl
module "storage" {
  source = "./modules/storage/object/wrapper"

  storage = {
    name = "my-bucket"

    ovh = {
      project_id = var.ovh_project_id
      region     = "GRA"
    }
  }
}
```

### Azure

```hcl
module "storage" {
  source = "./modules/storage/object/wrapper"

  storage = {
    name = "mystorageaccount"

    azure = {
      resource_group = "my-rg"
      location       = "westeurope"
    }
  }
}

output "connection_string" {
  value     = module.storage.connection_string
  sensitive = true
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `storage` | `object` | — | Sæt præcis ét af `storage.ovh` / `storage.azure` |
| `storage.name` | `string` | — | Navn på storage-ressourcen |
| `storage.ovh` | `object` | `null` | OVH-config |
| `storage.ovh.project_id` | `string` | — | OVH project ID |
| `storage.ovh.region` | `string` | `"GRA"` | OVH-region |
| `storage.ovh.versioning` | `string` | `"enabled"` | `"enabled"` eller `"disabled"` |
| `storage.ovh.encryption_sse` | `string` | `"AES256"` | SSE-algoritme |
| `storage.ovh.object_lock_days` | `number` | `0` | Retention i dage (0 = deaktiveret) |
| `storage.azure` | `object` | `null` | Azure-config |
| `storage.azure.resource_group` | `string` | — | Resource group-navn |
| `storage.azure.location` | `string` | — | Azure-region |
| `storage.azure.replication_type` | `string` | `"LRS"` | Replikeringstype |
| `storage.azure.versioning` | `bool` | `true` | Aktiver versionering |
| `storage.azure.retention_days` | `number` | `7` | Soft-delete dage |
| `storage.azure.container_name` | `string` | `"data"` | Blob-containernavn |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på storage-ressourcen |
| `storage_name` | Navn på storage-ressourcen |
| `storage_region` | Region |
| `connection_string` | Connection string *(sensitive)* — `null` for OVH |
