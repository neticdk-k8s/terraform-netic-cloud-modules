# Data disk — Wrapper

Fælles indgangspunkt til at oprette en selvstændig data-disk på enten **OVH**
(block storage volume) eller **Azure** (managed disk). Sæt enten `disk.ovh`
eller `disk.azure` — aldrig begge.

Disken oprettes **adskilt fra VM'en**, så dens livscyklus er afkoblet — den
overlever at VM'en genskabes. Tilknytning sker via VM-modulet
(`vm.ovh.disk_ids` / `vm.azure.data_disks`).

## Usage

### OVH

```hcl
module "disk" {
  source = "./modules/storage/disk/wrapper"

  disk = {
    name    = "app-data"
    size_gb = 100
    ovh     = { volume_type = "high-speed" }
  }
}
```

### Azure

```hcl
module "disk" {
  source = "./modules/storage/disk/wrapper"

  disk = {
    name    = "app-data"
    size_gb = 100
    azure   = { resource_group = "my-rg", location = "westeurope" }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `disk.name` | `string` | — | Disknavn |
| `disk.size_gb` | `number` | — | Størrelse i GB |
| `disk.tags` | `map(string)` | `{}` | Tags (kun Azure) |
| `disk.ovh` | `object` | `null` | Sæt for OVH |
| `disk.ovh.volume_type` | `string` | `"classic"` | `classic` \| `high-speed` \| `high-speed-gen2` |
| `disk.azure` | `object` | `null` | Sæt for Azure |
| `disk.azure.resource_group` | `string` | — | Resource group |
| `disk.azure.location` | `string` | — | Azure-region |
| `disk.azure.storage_account_type` | `string` | `"Premium_LRS"` | Disktype |
| `disk.azure.zone` | `string` | `null` | Availability zone — skal matche VM'ens zone hvis VM'en er zonal |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Disk-ID (volume-UUID for OVH, resource ID for Azure) |
| `name` | Disknavn |

## Brug i kontekst — tilknyt disken til en VM

### OVH

```hcl
module "disk" {
  source = "./modules/storage/disk/wrapper"
  disk   = { name = "app-data", size_gb = 100, ovh = { volume_type = "high-speed" } }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "app"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id
    ovh = {
      project_id    = var.ovh_project_id
      image_name    = "Ubuntu 24.04"
      network_names = [module.network.network_name]
      disk_ids      = [module.disk.id]
    }
  }
}
```

### Azure

```hcl
module "disk" {
  source = "./modules/storage/disk/wrapper"
  disk   = { name = "app-data", size_gb = 100, azure = { resource_group = "my-rg", location = "westeurope" } }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "app"
    size           = "Standard_D2s_v3"
    location       = "westeurope"
    resource_group = "my-rg"
    azure = {
      networks   = [{ subnet_id = module.network.subnet_ids["default"] }]
      data_disks = [{ disk_id = module.disk.id, lun = 0 }]
      image      = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2" }
    }
  }
}
```

> **OS-disken** styres derimod direkte på VM-modulet (`vm.ovh.os_disk` /
> `vm.azure.os_disk`) — den er en del af selve VM'en og kan ikke oprettes separat.
