# Network — Azure (VNet)

Provisions an Azure Virtual Network with one or more subnets.

## Resources created

| Resource | Description |
|----------|-------------|
| `azurerm_virtual_network` | The VNet |
| `azurerm_subnet` | One subnet per entry in `subnets` |

## Usage

```hcl
module "network" {
  source = "./modules/network/azure"

  network_name   = "my-vnet"
  location       = "westeurope"
  resource_group = "my-resource-group"
  address_space  = ["10.0.0.0/16"]

  subnets = {
    default = { cidr = "10.0.1.0/24" }
    aks     = { cidr = "10.0.2.0/24" }
    data    = { cidr = "10.0.3.0/24" }
  }
}

output "subnet_ids" { value = module.network.subnet_ids }
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `network_name` | `string` | Name of the VNet |
| `location` | `string` | Azure region (e.g. `"westeurope"`) |
| `resource_group` | `string` | Existing resource group |
| `address_space` | `list(string)` | VNet address space (e.g. `["10.0.0.0/16"]`) |
| `subnets` | `map(object)` | Map of subnet name → `{ cidr }` |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | ID of the VNet |
| `network_name` | Name of the VNet |
| `subnet_ids` | Map of subnet names → IDs — use to pass `subnet_id` to the VM module |

## Architecture

Azure VNets are **single-region resources**. This module provisions:
- One VNet in the specified region
- Multiple named subnets within that region (no regional separation)

This differs fundamentally from OVHcloud, which supports a single private network spanning multiple regions with one subnet per region.

To deploy across Azure regions, use separate module calls per region or implement VNet peering between regions (not included in this module).

## Notes

- Subnet names must be unique within the VNet.
- The `aks` subnet, if used with AKS, should have at least a `/22` prefix to allow enough IPs for node and pod scaling.
- Use `subnet_ids["default"]` to reference a specific subnet ID in other modules.
- Each VNet is isolated to a single region — multi-region deployments require additional peering configuration outside this module.
