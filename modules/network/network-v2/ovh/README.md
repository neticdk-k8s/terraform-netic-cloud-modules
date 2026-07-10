# Network v2 — OVH (DNS-capable subnet)

Samme som [`network/network/ovh`](../../network/ovh), men subnettet oprettes med
**`ovh_cloud_project_network_private_subnet_v2`** i stedet for den klassiske
ressource. Forskellen der betyder noget: v2 **udleverer DNS-resolvere over DHCP**
(den klassiske kan ikke), så instanser på det private net faktisk kan resolve
navne — nødvendigt for at pulle images o.l.

Standalone OVH-modul (v2-subnettet er OVH/OpenStack-specifikt) — ingen wrapper.

> **Adskilt fra det kørende net:** dette er et selvstændigt modul. Giv det et
> **andet `name` og `vlan_id`** end dit eksisterende net, så du kan teste det
> uden at røre noget der kører.

## Sådan adskiller det sig fra den klassiske `network/ovh`

| | klassisk (`network/ovh`) | v2 (dette modul) |
|--|--|--|
| Subnet-ressource | `..._private_subnet` | `..._private_subnet_v2` |
| DNS via DHCP | nej (kan ikke sættes) | **ja** (`dns_nameservers`, default OVH-resolver) |
| Default-rute | `no_gateway` | `enable_gateway_ip` |
| IP-pool | manuel `start`/`end` | overladt til OVH (undgår gateway-i-pool-overlap) |
| `network_id` til subnet | OVH pn-id | **OpenStack-UUID** (håndteret internt) |

## Usage

```hcl
module "network_v2" {
  source = "./modules/network/network-v2/ovh"

  ovh_project_id = var.ovh_project_id

  network = {
    name    = "vnet-netic-test-v2"   # NYT navn — ikke det kørende net
    vlan_id = 334                     # NYT vlan_id
    regions = [
      {
        region = "EU-SOUTH-MIL"
        subnet = "10.0.70.0/24"
        dhcp   = true
        # dns_nameservers = ["1.1.1.1"]   # udelad = OVH's default resolver
      }
    ]
  }
}

output "gateway_ips" { value = module.network_v2.gateway_ips }
output "subnet_ids"  { value = module.network_v2.subnet_ids }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ovh_project_id` | `string` | — | OVH project ID / service name |
| `network.name` | `string` | — | Navn på privat net (brug et nyt til test) |
| `network.vlan_id` | `number` | — | vRack VLAN ID (brug et nyt til test) |
| `network.regions[].region` | `string` | — | OVH-region, fx `"EU-SOUTH-MIL"` |
| `network.regions[].subnet` | `string` | — | CIDR, fx `"10.0.70.0/24"` |
| `network.regions[].dhcp` | `bool` | `true` | DHCP på subnettet |
| `network.regions[].no_gateway` | `bool` | `false` | `true` slår default-rute fra |
| `network.regions[].dns_nameservers` | `list(string)` | `null` | Custom DNS; `null` = OVH default resolver |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | OpenStack netværks-UUID (første region) |
| `network_ids` | Map region → OpenStack netværks-UUID |
| `network_name` | Netværkets navn |
| `subnet_ids` | Map region → OpenStack subnet-UUID |
| `gateway_ips` | Map region → subnettets gateway-IP (default-ruten fra DHCP) |
