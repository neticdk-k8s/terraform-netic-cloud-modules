# Object Storage — Wrapper

Fælles indgangspunkt til at oprette object storage på enten **Azure** (Blob Storage) eller **OVH** (S3-kompatibel bucket).

## Usage

### OVH

```hcl
module "storage" {
  source         = "./modules/storage/object/wrapper"
  cloud_provider = "ovh"
  name           = "my-bucket"

  ovh = {
    project_id = var.ovh_project_id
    region     = "GRA"
  }
}
```

### Azure

```hcl
module "storage" {
  source         = "./modules/storage/object/wrapper"
  cloud_provider = "azure"
  name           = "mystorageaccount"

  azure = {
    resource_group = "my-rg"
    location       = "westeurope"
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
| `cloud_provider` | `string` | — | `"ovh"` eller `"azure"` |
| `name` | `string` | — | Navn på storage-ressourcen |
| `ovh` | `object` | `null` | OVH-config. Kræves når `cloud_provider = "ovh"` |
| `ovh.project_id` | `string` | — | OVH project ID |
| `ovh.region` | `string` | `"GRA"` | OVH-region |
| `ovh.versioning` | `string` | `"enabled"` | `"enabled"` eller `"disabled"` |
| `ovh.encryption_sse` | `string` | `"AES256"` | SSE-algoritme |
| `ovh.object_lock_days` | `number` | `0` | Retention i dage (0 = deaktiveret) |
| `azure` | `object` | `null` | Azure-config. Kræves når `cloud_provider = "azure"` |
| `azure.resource_group` | `string` | — | Resource group-navn |
| `azure.location` | `string` | — | Azure-region |
| `azure.replication_type` | `string` | `"LRS"` | Replikeringstype |
| `azure.versioning` | `bool` | `true` | Aktiver versionering |
| `azure.retention_days` | `number` | `7` | Soft-delete dage |
| `azure.container_name` | `string` | `"data"` | Blob-containernavn |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på storage-ressourcen |
| `storage_name` | Navn på storage-ressourcen |
| `storage_region` | Region |
| `connection_string` | Connection string *(sensitive)* — `null` for OVH |
