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
| `network.ovh` | `object` | `null` | OVH-config — sæt for at vælge OVH |
| `network.ovh.project_id` | `string` | — | OVH project ID |
| `network.ovh.vlan_id` | `number` | — | VLAN ID (f.eks. `100`) |
| `network.ovh.regions` | `list(object)` | — | Liste af `{ region, subnet, dhcp?, no_gateway?, ip_allocation_start?, ip_allocation_stop? }` |
| `network.azure` | `object` | `null` | Azure-config — sæt for at vælge Azure |
| `network.azure.location` | `string` | — | Azure-region |
| `network.azure.resource_group` | `string` | — | Resource group-navn |
| `network.azure.address_space` | `list(string)` | — | VNet address space (f.eks. `["10.0.0.0/16"]`) |
| `network.azure.subnets` | `map(object)` | — | Map af subnetnavn → `{ cidr }` |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | ID på det oprettede netværk |
| `network_name` | Navn på netværket |
| `subnet_ids` | Map af region/navn → subnet ID |
| `nsg_ids` | Map af subnetnavn → NSG ID (kun Azure, ellers null) |
