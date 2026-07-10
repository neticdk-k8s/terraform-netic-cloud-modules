# Network — Wrapper

Fælles indgangspunkt til at provisionere et privat netværk på enten **OVHcloud** (vRack) eller **Azure** (VNet). Sæt enten `network.ovh` eller `network.azure` — aldrig begge.

## Arkitekturforskelle

| Aspekt | Azure | OVHcloud |
|--------|-------|----------|
| **Scope** | Enkelt region | Flere regioner |
| **Subnets** | Mange per region | Et per region |
| **Multi-region** | VNet peering | Indbygget via VLAN |

## Usage

### OVHcloud

```hcl
module "network" {
  source = "./modules/network/network/wrapper"

  network = {
    name = "my-private-network"

    ovh = {
      project_id = var.ovh_project_id
      vlan_id    = 100
      regions = [
        { region = "GRA11", subnet = "10.0.0.0/24" },
        { region = "SBG5",  subnet = "10.0.1.0/24", dhcp = false }
      ]
    }
  }
}

output "subnet_ids" { value = module.network.subnet_ids }
```

### Azure

```hcl
module "network" {
  source = "./modules/network/network/wrapper"

  network = {
    name = "my-vnet"

    azure = {
      location       = "westeurope"
      resource_group = "my-rg"
      address_space  = ["10.0.0.0/16"]
      subnets = {
        default = { cidr = "10.0.1.0/24" }
        aks     = { cidr = "10.0.2.0/24" }
      }
    }
  }
}

output "subnet_ids" { value = module.network.subnet_ids }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `network.name` | `string` | — | Netværksnavn |
| `network.tags` | `map(string)` | `{}` | Tags (kun Azure — vnet + NSG'er; OVH private net har ikke tags) |
| `network.ovh` | `object` | `null` | OVH-config — sæt for at vælge OVH |
| `network.ovh.project_id` | `string` | — | OVH project ID |
| `network.ovh.vlan_id` | `number` | — | VLAN ID (f.eks. `100`) |
| `network.ovh.regions` | `list(object)` | — | Liste af `{ region, subnet, dhcp?, no_gateway?, ip_allocation_start?, ip_allocation_stop? }` |
| `network.azure` | `object` | `null` | Azure-config — sæt for at vælge Azure |
| `network.azure.location` | `string` | — | Azure-region |
| `network.azure.resource_group` | `string` | — | Resource group-navn |
| `network.azure.address_space` | `list(string)` | — | VNet address space (f.eks. `["10.0.0.0/16"]`) |
| `network.azure.subnets` | `map(object)` | — | Map af subnetnavn → `{ cidr }` |
| `network.azure.create_default_nsgs` | `bool` | `true` | Auto-opret en (tom) NSG pr. subnet + association. Slå fra hvis NSG'er styres separat (fx via [`security-group`](../../security-group/wrapper)-modulet på NIC-niveau) — to NSG-lag (subnet + NIC) evalueres begge og kan give svært-debugbare drops |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | ID på det oprettede netværk |
| `network_name` | Navn på netværket |
| `subnet_ids` | Map af region/navn → subnet ID |
| `network_ids` | Map af region → OpenStack netværks-UUID (kun OVH, null for Azure) |
| `nsg_ids` | Map af subnetnavn → NSG ID (kun Azure; tomt map hvis `create_default_nsgs = false`, null for OVH) |

## Brug i kontekst — en VM på netværket

### OVH

OVH's VM-modul tilknytter private net ved **navn** (`network_name`-outputtet):

```hcl
module "network" {
  source  = "./modules/network/network/wrapper"
  network = {
    name = "app-net"
    ovh  = { project_id = var.ovh_project_id, vlan_id = 100, regions = [{ region = "GRA11", subnet = "10.0.0.0/24" }] }
  }
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
    }
  }
}
```

### Azure

Azure's VM-modul tilknytter et NIC til et **subnet** via `subnet_ids`-outputtet:

```hcl
module "network" {
  source  = "./modules/network/network/wrapper"
  network = {
    name = "app-net"
    azure = {
      location       = "westeurope"
      resource_group = "my-rg"
      address_space  = ["10.0.0.0/16"]
      subnets        = { default = { cidr = "10.0.1.0/24" } }
    }
  }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "app"
    size           = "Standard_D2s_v3"
    location       = "westeurope"
    resource_group = "my-rg"
    azure = {
      networks = [{ subnet_id = module.network.subnet_ids["default"] }]
      image    = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2" }
    }
  }
}
```
