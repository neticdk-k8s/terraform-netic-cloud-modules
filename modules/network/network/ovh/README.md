# Network — OVHcloud

Privat vRack-net med ét subnet pr. region. Subnettet oprettes med
`ovh_cloud_project_network_private_subnet_v2`, som (i modsætning til det
klassiske subnet) understøtter custom gateway-IP og DNS via DHCP.

Bruges normalt via [`../wrapper`](../wrapper) (fælles interface for OVH og Azure),
men kan også kaldes direkte.

> Modulet erstatter det tidligere `network-v2/ovh`. Ressource-adresserne er de
> samme, så et direkte kald kan skifte `source` fra `network-v2/ovh` til
> `network/ovh` uden ændringer i plan.

## Ressourcer

| Ressource | Beskrivelse |
|-----------|-------------|
| `ovh_cloud_project_network_private` | Privat vRack-net (ét VLAN på tværs af regioner) |
| `ovh_cloud_project_network_private_subnet_v2` | Subnet pr. region (gateway, DHCP, DNS, allocation pool) |
| `openstack_networking_subnet_route_v2` | Host routes pr. subnet (DHCP option 121) — kun hvis `host_routes` er sat |

## Usage

```hcl
module "network" {
  source = "github.com/neticdk-k8s/terraform-netic-cloud-modules//modules/network/network/ovh"

  ovh_project_id = var.ovh_project_id

  network = {
    name    = "vnet-example"
    vlan_id = 334
    regions = [
      {
        region = "EU-SOUTH-MIL"
        subnet = "10.0.25.0/24"
        dhcp   = true

        # Valgfrit:
        # ip_allocation_start = 10    # DHCP-pool .10-.200 (begge eller ingen)
        # ip_allocation_stop  = 200
        # gateway_host        = 254   # firewall/NVA på .254 som default route
        # host_routes = [
        #   { destination = "192.168.24.0/22", nexthop = "10.0.25.254" } # fx Azure via VPN
        # ]
        # dns_nameservers = ["1.1.1.1"] # null = OVH's resolver
      }
    ]
  }
}
```

### Custom gateway ("som i Azure")

Routing sidder på **subnettet** i OpenStack, ikke på netværket. `gateway_host`
svarer til en Azure route table med `0.0.0.0/0 → NVA`, og `host_routes` til
specifikke UDR-ruter. Begge udleveres via DHCP (virker ved lease/renew).

Firewall-porten på gateway-IP'en oprettes separat med
[`../../port/ovh`](../../port/ovh) (`ip_forwarding = true`, `dhcp_lease = false`),
så anti-spoofing er slået fra og firewallen ikke får en default route til sig selv.

> MKS Standard (3AZ-regioner) kræver en OVH-router som gateway på node-subnettet
> — en firewall på `.254` accepteres (endnu) ikke dér.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ovh_project_id` | `string` | — | OVH project ID / service name |
| `network.name` | `string` | — | Netværkets navn |
| `network.vlan_id` | `number` | — | vRack VLAN ID |
| `network.regions[].region` | `string` | — | OVH-region, fx `"EU-SOUTH-MIL"` |
| `network.regions[].subnet` | `string` | — | CIDR, fx `"10.0.25.0/24"` |
| `network.regions[].dhcp` | `bool` | `true` | DHCP på subnettet |
| `network.regions[].no_gateway` | `bool` | `false` | `true` = ingen gateway/default route |
| `network.regions[].ip_allocation_start` | `number` | `null` | Første host-index i DHCP-poolen (sæt begge eller ingen). Wrapperen har default `10` |
| `network.regions[].ip_allocation_stop` | `number` | `null` | Sidste host-index i DHCP-poolen. Wrapperen har default `200` |
| `network.regions[].gateway_host` | `number` | `null` | Host-index for custom gateway, fx `254`. `null` = OVH vælger første IP |
| `network.regions[].host_routes` | `list(object({destination, nexthop}))` | `[]` | Statiske ruter via DHCP (option 121) |
| `network.regions[].dns_nameservers` | `list(string)` | `null` | Custom DNS; `null` = OVH default resolver |

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | OpenStack netværks-UUID (første region) |
| `network_ids` | Map region → OpenStack netværks-UUID |
| `network_name` | Netværkets navn |
| `subnet_ids` | Map region → OpenStack subnet-UUID |
| `gateway_ips` | Map region → subnettets gateway-IP |
