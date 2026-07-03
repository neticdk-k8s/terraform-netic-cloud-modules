# Data disk — OVHcloud

Opretter en selvstændig block storage volume (Cinder). Livscyklus er afkoblet
fra VM'en — disken overlever at VM'en genskabes. Tilknyt via `vm.ovh.disk_ids`.

Region følger openstack-providerens konfiguration.

## Usage

```hcl
module "disk" {
  source = "./modules/storage/disk/ovh"

  disk = {
    name        = "app-data"
    size_gb     = 100
    volume_type = "high-speed"
  }
}
```

## Inputs

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `disk.name` | `string` | — | Volume-navn |
| `disk.size_gb` | `number` | — | Størrelse i GB |
| `disk.volume_type` | `string` | `"classic"` | `classic` \| `high-speed` \| `high-speed-gen2` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Volume-UUID — gives til VM via `vm.ovh.disk_ids` |
| `name` | Volume-navn |
