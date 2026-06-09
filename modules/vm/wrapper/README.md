# VM — Wrapper

Fælles indgangspunkt til at provisionere en virtuel maskine på enten **OVHcloud** eller **Azure**. Sæt enten `vm.ovh` eller `vm.azure` — aldrig begge.

## Usage

### OVHcloud

```hcl
module "vm" {
  source = "./modules/vm/wrapper"

  vm = {
    name           = "my-server"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id

    ovh = {
      project_id    = var.ovh_project_id
      image_name    = "Ubuntu 24.04"
      network_names = ["my-private-network", "Ext-Net"]
    }
  }
}

output "ssh_key" { value = module.vm.ssh_private_key; sensitive = true }
output "ip"      { value = module.vm.public_ip }
```

### Azure

```hcl
module "vm" {
  source = "./modules/vm/wrapper"

  vm = {
    name             = "my-server"
    size             = "Standard_D2s_v3"
    location         = "westeurope"
    resource_group   = "my-rg"
    create_public_ip = true

    azure = {
      subnet_id = module.network.subnet_ids["default"]
      image = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
      }
    }
  }
}

output "ssh_key" { value = module.vm.ssh_private_key; sensitive = true }
output "ip"      { value = module.vm.public_ip }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm.name` | `string` | — | VM-navn |
| `vm.size` | `string` | — | VM-størrelse (f.eks. `"b2-7"` / `"Standard_D2s_v3"`) |
| `vm.location` | `string` | — | Region/location |
| `vm.resource_group` | `string` | — | Resource group (Azure) eller OVH project ID |
| `vm.os_type` | `string` | `"Linux"` | `"Linux"` eller `"Windows"` |
| `vm.admin_pass` | `string` | `null` | Admin-password (kræves til Windows) |
| `vm.ssh_public_key` | `string` | `null` | SSH public key — auto-genereres hvis ikke angivet |
| `vm.create_public_ip` | `bool` | `false` | Opret public IP |
| `vm.user_data` | `string` | `null` | Cloud-init / userdata-script |
| `vm.tags` | `map(string)` | `{}` | Tags |
| `vm.ovh` | `object` | `null` | OVH-specifik config — sæt for at vælge OVH |
| `vm.ovh.project_id` | `string` | — | OVH project ID |
| `vm.ovh.image_name` | `string` | — | OVH image-navn (f.eks. `"Ubuntu 24.04"`) |
| `vm.ovh.network_names` | `list(string)` | `[]` | Navne på private netværk at tilknytte |
| `vm.ovh.security_groups` | `list(string)` | `["default"]` | Security groups |
| `vm.ovh.power_state` | `string` | `"active"` | `"active"` eller `"shutoff"` |
| `vm.azure` | `object` | `null` | Azure-specifik config — sæt for at vælge Azure |
| `vm.azure.subnet_id` | `string` | — | Subnet ID til NIC'et |
| `vm.azure.admin_username` | `string` | `"azureuser"` | Admin-brugernavn |
| `vm.azure.image` | `object` | — | `{ publisher, offer, sku, version? }` |

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Navn på VM'en |
| `vm_ip` | Primær privat IPv4-adresse |
| `public_ip` | Public IP (null hvis ikke oprettet) |
| `ssh_private_key` | Genereret SSH private key *(sensitive)* — null hvis nøgle blev angivet |
