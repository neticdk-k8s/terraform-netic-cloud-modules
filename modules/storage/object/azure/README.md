# Object Storage — Azure

Opretter en Azure Storage Account (StorageV2, Standard) med en blob-container, versionering og soft-delete.

## Usage

```hcl
module "storage" {
  source = "./modules/storage/object/azure"

  storage = {
    name           = "mystorageaccount"
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
| `storage.name` | `string` | — | Navn på storage account (3-24 tegn, lowercase alphanumerisk, globalt unikt) |
| `storage.resource_group` | `string` | — | Azure resource group-navn |
| `storage.location` | `string` | — | Azure-region (f.eks. `"westeurope"`) |
| `storage.replication_type` | `string` | `"LRS"` | `"LRS"`, `"GRS"`, `"ZRS"` etc. |
| `storage.versioning` | `bool` | `true` | Aktiver blob-versionering |
| `storage.retention_days` | `number` | `7` | Soft-delete retention i dage (0 = deaktiveret) |
| `storage.container_name` | `string` | `"data"` | Navn på blob-containeren |
| `storage.tags` | `map(string)` | `{}` | Tags på storage account'en |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på storage account'en |
| `storage_name` | Navn på storage account'en |
| `storage_region` | Region for storage account'en |
| `connection_string` | Primary connection string *(sensitive)* |
