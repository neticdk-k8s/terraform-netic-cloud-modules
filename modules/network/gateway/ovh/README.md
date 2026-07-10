# Gateway — OVH

Opretter en **OVH Public Cloud Gateway** (`ovh_cloud_project_gateway`) — en managed
gateway der giver instanser på et privat net **udgående internetadgang via SNAT**.
Instanserne behøver altså ikke hver deres public IP for at nå internettet.

Modulet er **subnet-drevet**: angiv én eller flere subnet-UUID'er i `subnet_ids`
(brug outputtet `subnet_ids[region]` fra [`network/network/ovh`](../../network/ovh)).
Det **første** subnet er den primære tilknytning; yderligere subnets tilføjes som
interfaces (`ovh_cloud_project_gateway_interface`), så samme gateway også betjener
**flere netværk** i samme region. Hvert subnets netværk slås automatisk op via en
OpenStack-datakilde, så du ikke selv skal angive `network_id`.

## Usage

```hcl
module "network" {
  source = "./modules/network/network/ovh"
  # ... opretter privat net + subnet i fx GRA11
}

module "gateway" {
  source = "./modules/network/gateway/ovh"

  gateway = {
    name         = "egress-gw"
    service_name = var.ovh_project_id
    region       = "GRA11"
    model        = "s"
    subnet_ids = [
      module.network.subnet_ids["GRA11"],
      # module.other_network.subnet_ids["GRA11"], # flere netværk, samme gateway
    ]
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `gateway.name` | `string` | — | Gateway-navn |
| `gateway.service_name` | `string` | — | OVH public cloud project ID (ovh_project_id) |
| `gateway.region` | `string` | — | OVH-region, fx `"GRA11"` (alle subnets skal være i denne region) |
| `gateway.model` | `string` | `"s"` | Størrelse/throughput-tier: `"s"`, `"m"` eller `"l"` |
| `gateway.subnet_ids` | `list(string)` | — | OpenStack subnet-UUID'er; `[0]` = primær, resten = ekstra interfaces (min. 1) |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Gatewayens ID |
| `status` | Provisioneringsstatus |
| `external_information` | Ekstern netværksinfo inkl. gatewayens SNAT public IP(er) |
| `interface_ids` | Map fra ekstra subnet-UUID til interface-ID |
