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
      network_names = ["my-private-network"]
    }
  }
}

output "ssh_key" { value = module.vm.ssh_private_key; sensitive = true }
output "ip"      { value = module.vm.public_ip }
```

### OVHcloud — firewall/router VM (disabled anti-spoofing)

A VM that must route/forward traffic not addressed to its own IP (firewall, NAT gateway, VPN endpoint) needs a port with port security disabled. On OVH that port is created separately with [`modules/network/port/ovh`](../../network/port/ovh) and passed in via `port_ids`:

```hcl
module "port" {
  source   = ".../modules/network/port/ovh"
  for_each = { for n in var.networks : n.name => n }

  port = {
    name          = "${each.value.name}-opnsense-port"
    network_id    = module.network[each.key].network_id
    subnet_id     = module.network[each.key].subnet_ids[each.value.regions[0].region]
    static_ip     = cidrhost(each.value.regions[0].subnet, 254)
    ip_forwarding = true
  }
}

module "vm" {
  source = "./modules/vm/wrapper"

  vm = {
    name             = "opnsense-fw"
    size             = "b2-7"
    location         = "GRA11"
    resource_group   = var.ovh_project_id
    create_public_ip = true

    ovh = {
      project_id = var.ovh_project_id
      image_name = "opnsense"
      port_ids   = [for p in module.port : p.id]
    }
  }
}
```

On Azure there is no separate port object — IP forwarding is a NIC property set directly on the VM; see the Azure firewall example below.

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
      networks = [{ subnet_id = module.network.subnet_ids["default"] }]
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

### Azure — firewall/router VM (`ip_forwarding`)

Samme koncept som på OVH, men Azure kalder det "IP forwarding", og det slår **kun** forwarding til på NIC'en — Network Security Groups håndhæves stadig uafhængigt og skal selv tillade trafikken. Se [`vm/azure` README](../azure/README.md#firewall-router-vm-with-anti-spoofing-disabled-ip_forwarding).

```hcl
module "vm" {
  source = "./modules/vm/wrapper"

  vm = {
    name             = "opnsense-fw"
    size             = "Standard_D2s_v3"
    location         = "westeurope"
    resource_group   = "my-rg"
    create_public_ip = true

    azure = {
      networks = [
        { subnet_id = module.network.subnet_ids["public"] },
        {
          subnet_id                 = module.network.subnet_ids["private"]
          static_ip                 = "10.0.25.254"
          ip_forwarding             = true
          network_security_group_id = module.security_group.id
        },
      ]
      image = {
        publisher = "..."
        offer     = "..."
        sku       = "..."
      }
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm.name` | `string` | — | VM-navn |
| `vm.size` | `string` | — | VM-størrelse (f.eks. `"b2-7"` / `"Standard_D2s_v3"`) |
| `vm.location` | `string` | — | Region/location (bruges kun af Azure — OVH-regionen styres af provider-konfigurationen) |
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
| `vm.ovh.network_names` | `list(string)` | `[]` | Private netværk at tilknytte ved navn (DHCP, port security til) |
| `vm.ovh.port_ids` | `list(string)` | `[]` | Præ-oprettede port-UUID'er at tilknytte (fx fra [`network/port/ovh`](../../network/port/ovh)) — bruges til statisk IP og/eller deaktiveret port security |
| `vm.ovh.disk_ids` | `list(string)` | `[]` | Præ-oprettede volume-UUID'er at tilknytte som data-diske (fra [`storage/disk`](../../storage/disk/wrapper)) |
| `vm.ovh.os_disk` | `object` | `null` | Boot-from-volume med valgfri størrelse/type: `{ size_gb, volume_type? }` — kræver flex-flavor (fx `"b2-7-flex"`) |
| `vm.ovh.security_groups` | `list(string)` | `["default"]` | Security groups |
| `vm.ovh.power_state` | `string` | `"active"` | `"active"` eller `"shutoff"` |
| `vm.azure` | `object` | `null` | Azure-specifik config — sæt for at vælge Azure |
| `vm.azure.networks` | `list(object)` | `[]` | NIC'er at oprette, i rækkefølge (mindst ét påkrævet). `networks[0]` er primær NIC og får public IP'en. Sæt `static_ip`/`ip_forwarding`/`network_security_group_id` pr. NIC — se [`vm/azure` README](../azure/README.md) |
| `vm.azure.admin_username` | `string` | `"azureuser"` | Admin-brugernavn |
| `vm.azure.zone` | `string` | `null` | Availability zone (`"1"`/`"2"`/`"3"`) |
| `vm.azure.boot_diagnostics` | `bool` | `false` | Managed-storage boot diagnostics |
| `vm.azure.os_disk` | `object` | se defaults | `{ size_gb?, storage_account_type? ("Premium_LRS"), caching? ("ReadWrite") }` |
| `vm.azure.data_disks` | `list(object)` | `[]` | Præ-oprettede managed disks at tilknytte: `{ disk_id, lun, caching? }` (fra [`storage/disk`](../../storage/disk/wrapper)) |
| `vm.azure.image` | `object` | — | `{ publisher, offer, sku, version? }` |

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Navn på VM'en |
| `vm_ip` | Primær privat IPv4-adresse |
| `public_ip` | Public IP (null hvis ikke oprettet — og null på OVH når WAN er tilknyttet via `port_ids`; brug i så fald port-modulets `ip_address`) |
| `ssh_private_key` | Genereret SSH private key *(sensitive)* — null hvis nøgle blev angivet |
| `network_interface_ids` | NIC-id'er i samme rækkefølge som `vm.azure.networks` (kun Azure — null for OVH) |
