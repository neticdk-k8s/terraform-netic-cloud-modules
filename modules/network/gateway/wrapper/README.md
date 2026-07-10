# Gateway — Wrapper

Fælles indgangspunkt til en **gateway for udgående ekstern (internet) adgang** på
enten **Azure** eller **OVH**. Sæt enten `gateway.azure` eller `gateway.ovh` —
aldrig begge.

Fælles, cloud-agnostiske indstillinger (`name`, `region`, `subnet_ids`, `tags`)
ligger i toppen. Kun det der er ægte cloud-specifikt ligger under `azure` / `ovh`.

Begge giver VM'er på et privat net en stabil udgående public IP via SNAT:
- **Azure** opretter en `azurerm_nat_gateway`, binder `public_ip_id` og associerer `subnet_ids`.
- **OVH** opretter en `ovh_cloud_project_gateway` på `subnet_ids` (ekstra subnets bliver interfaces).

> OVH-gateways understøtter ikke tags, så `gateway.tags` anvendes kun på Azure.

## Usage

### Azure

```hcl
module "gateway" {
  source = "./modules/network/gateway/wrapper"

  gateway = {
    name       = "egress-gw"
    region     = "westeurope"
    subnet_ids = [module.network.subnet_ids["default"]]

    azure = {
      resource_group = "my-rg"
      public_ip_id   = module.pip.id
    }
  }
}
```

### OVH

```hcl
module "gateway" {
  source = "./modules/network/gateway/wrapper"

  gateway = {
    name       = "egress-gw"
    region     = "GRA11"
    subnet_ids = [module.network.subnet_ids["GRA11"]] # første = primær, resten = ekstra netværk

    ovh = {
      project_id = var.ovh_project_id
    }
  }
}
```

## Inputs

Sæt præcis ét af `gateway.azure` / `gateway.ovh`.

Fælles (cloud-agnostisk):

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `gateway.name` | `string` | — | Gateway-navn |
| `gateway.region` | `string` | — | Azure location / OVH region |
| `gateway.subnet_ids` | `list(string)` | `[]` | Subnets gatewayen betjener (OVH: `[0]` = primær, resten = ekstra interfaces; kræver min. 1) |
| `gateway.tags` | `map(string)` | `{}` | Tags (kun Azure) |

### `gateway.azure`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group` | `string` | — | Resource group-navn |
| `public_ip_id` | `string` | — | Resource ID på en Standard public IP (udgående adresse) |
| `idle_timeout_in_minutes` | `number` | `4` | SNAT idle timeout |

### `gateway.ovh`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project_id` | `string` | — | OVH public cloud project ID (ovh_project_id) |
| `model` | `string` | `"s"` | Størrelse/throughput-tier: `"s"`, `"m"` eller `"l"` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Gatewayens ID |
| `external_information` | Udgående info — SNAT public IP(er) for OVH, public IP + subnets for Azure |
