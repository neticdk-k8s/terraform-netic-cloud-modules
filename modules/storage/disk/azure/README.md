# Data disk — Azure

Opretter en selvstændig managed disk. Livscyklus er afkoblet fra VM'en —
disken overlever at VM'en genskabes. Tilknyt via `vm.azure.data_disks`.

## Usage

```hcl
module "disk" {
  source = "./modules/storage/disk/azure"

  disk = {
    name           = "app-data"
    size_gb        = 100
    resource_group = "my-rg"
    location       = "westeurope"
  }
}
```

## Inputs

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `disk.name` | `string` | — | Disknavn |
| `disk.size_gb` | `number` | — | Størrelse i GB |
| `disk.resource_group` | `string` | — | Resource group |
| `disk.location` | `string` | — | Azure-region |
| `disk.storage_account_type` | `string` | `"Premium_LRS"` | Disktype (`Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, …) |
| `disk.zone` | `string` | `null` | Availability zone — skal matche VM'ens zone hvis VM'en er zonal |
| `disk.tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID — gives til VM via `vm.azure.data_disks[].disk_id` |
| `name` | Disknavn |
