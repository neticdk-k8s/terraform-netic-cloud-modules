# Object Storage — Azure

Opretter en Azure Storage Account (StorageV2, Standard) med en blob-container, versionering og soft-delete.

## Usage

```hcl
module "storage" {
  source = "./modules/storage/object/azure"

  name           = "mystorageaccount"
  resource_group = "my-rg"
  location       = "westeurope"
}

output "connection_string" {
  value     = module.storage.connection_string
  sensitive = true
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Navn på storage account (3-24 tegn, lowercase alphanumerisk, globalt unikt) |
| `resource_group` | `string` | — | Azure resource group-navn |
| `location` | `string` | — | Azure-region (f.eks. `"westeurope"`) |
| `replication_type` | `string` | `"LRS"` | `"LRS"`, `"GRS"`, `"ZRS"` etc. |
| `versioning` | `bool` | `true` | Aktiver blob-versionering |
| `retention_days` | `number` | `7` | Soft-delete retention i dage (0 = deaktiveret) |
| `container_name` | `string` | `"data"` | Navn på blob-containeren |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på storage account'en |
| `storage_name` | Navn på storage account'en |
| `storage_region` | Region for storage account'en |
| `connection_string` | Primary connection string *(sensitive)* |
