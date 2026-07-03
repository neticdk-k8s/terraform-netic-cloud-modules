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
| `storage.tags` | `map(string)` | `{}` | Tags (kun Azure — OVH object storage har ikke tags) |

## Outputs

| Name | Description |
|------|-------------|
| `storage_id` | ID på storage-ressourcen |
| `storage_name` | Navn på storage-ressourcen |
| `storage_region` | Region |
| `connection_string` | Connection string *(sensitive)* — `null` for OVH |

## Brug i kontekst — giv en app adgang til storage

### Azure — connection string til en VM via cloud-init

Azure eksponerer en `connection_string`, som en app kan bruge direkte. Injicér
den fx via VM'ens `user_data`:

```hcl
module "storage" {
  source  = "./modules/storage/object/wrapper"
  storage = { name = "appdata", azure = { resource_group = "my-rg", location = "westeurope" } }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "app"
    size           = "Standard_D2s_v3"
    location       = "westeurope"
    resource_group = "my-rg"
    user_data      = <<-EOT
      #cloud-config
      write_files:
        - path: /etc/app/storage.env
          content: "AZURE_STORAGE_CONNECTION_STRING=${module.storage.connection_string}"
    EOT
    azure = {
      networks = [{ subnet_id = module.network.subnet_ids["default"] }]
      image    = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2" }
    }
  }
}
```

> `connection_string` er `sensitive` — den havner i Terraform-state. Undgå at
> `output`'e den ukrypteret, og foretræk en secrets manager til produktion.

### OVH — S3-kompatibel: navn/region + separate credentials

OVH returnerer **ikke** en connection string (`connection_string = null`). Object
storage er S3-kompatibel og tilgås med separate S3-credentials (OVH `s3_credentials`
/ en bruger-key). Brug `storage_name` + `storage_region` som bucket-reference i
din app-config, og udlever S3-nøglerne separat (fx via en secrets manager):

```hcl
module "storage" {
  source  = "./modules/storage/object/wrapper"
  storage = { name = "appdata", ovh = { project_id = var.ovh_project_id, region = "GRA" } }
}

# App-konfiguration peger på bucket'en; S3-endpoint følger regionen:
#   bucket   = module.storage.storage_name
#   region   = module.storage.storage_region
#   endpoint = "https://s3.${module.storage.storage_region}.io.cloud.ovh.net"
```
