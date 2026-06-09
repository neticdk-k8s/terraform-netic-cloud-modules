# Network — OVHcloud

Provisions a private vRack network and one subnet per region on OVHcloud. A single VLAN spans all regions; subnets are created independently per region with configurable DHCP and IP allocation ranges.

## Resources created

| Resource | Description |
|----------|-------------|
| `ovh_cloud_project_network_private` | Private vRack network (one VLAN across all regions) |
| `ovh_cloud_project_network_private_subnet` | Subnet per region with DHCP and allocation range |

## Usage

```hcl
module "network" {
  source = "./modules/network/ovh"

  ovh_project_id = var.ovh_project_id
  network_name   = "my-private-network"
  vlan_id        = 100

  regions = [
    {
      region = "GRA11"
      subnet = "10.0.0.0/24"
    },
    {
      region              = "SBG5"
      subnet              = "10.0.1.0/24"
      dhcp                = false
      ip_allocation_start = 50
      ip_allocation_stop  = 150
    }
  ]
}
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `ovh_project_id` | `string` | OVH Public Cloud project ID |
| `network_name` | `string` | Name of the private network |
| `vlan_id` | `number` | VLAN ID — must be unique per vRack |
| `regions` | `list(object)` | Regions and their subnet configurations (see below) |
| `no_gateway` | `bool` | Disable gateway on all subnets (default: `false`) |

### `regions` list entry

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `region` | `string` | — | OVH region (e.g. `"GRA11"`) |
| `subnet` | `string` | — | Subnet CIDR (e.g. `"10.0.0.0/24"`) |
| `dhcp` | `bool` | `true` | Enable DHCP on the subnet |
| `ip_allocation_start` | `number` | `10` | Host offset for the DHCP pool start address |
| `ip_allocation_stop` | `number` | `200` | Host offset for the DHCP pool stop address |

`ip_allocation_start = 10` on subnet `10.0.0.0/24` resolves to `10.0.0.10`.

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | ID of the private network |
| `network_name` | Name of the private network |
| `subnet_ids` | Map of region → subnet ID |

## Provider

```hcl
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
```

## Architecture

OVHcloud private networks are **multi-region resources** with a unique design:
- One private vRack network spans all specified regions
- One subnet per region (not multiple subnets per region)
- Each subnet has independent DHCP and IP allocation settings

This differs fundamentally from Azure, where a VNet exists in a single region but can contain multiple subnets within that region. OVH's architecture prioritizes network continuity across regions over subnet flexibility within a region.

## Notes

- OVHcloud allows only one network per VLAN ID within a vRack. Reusing a `vlan_id` across multiple module calls will cause a conflict.
- The network name is passed to VMs via `network_names` in the `vm` module — make sure they match.
- One subnet per region is a platform constraint; you cannot create multiple subnets in the same region using this module.
