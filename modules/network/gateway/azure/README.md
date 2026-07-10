# Gateway — Azure

Opretter en **Azure NAT Gateway** (`azurerm_nat_gateway`) og knytter den til en
public IP samt et eller flere subnets. Alle VM'er på de tilknyttede subnets får
derved **udgående internetadgang via én stabil public IP** (SNAT) — uden at hver
VM skal have sin egen public IP.

Public IP'en oprettes ikke her — send `public_ip_id` ind (fx fra
[`network/public-ip`](../../public-ip)). IP'en skal være **Standard SKU**.

## Usage

```hcl
module "pip" {
  source    = "./modules/network/public-ip/azure"
  public_ip = { name = "egress-pip", location = "westeurope", resource_group = "my-rg" }
}

module "gateway" {
  source = "./modules/network/gateway/azure"

  gateway = {
    name           = "egress-gw"
    location       = "westeurope"
    resource_group = "my-rg"
    public_ip_id   = module.pip.id
    subnet_ids     = [module.network.subnet_ids["default"]]
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `gateway.name` | `string` | — | Navn på NAT gateway'en |
| `gateway.location` | `string` | — | Azure-region (fx `"westeurope"`) |
| `gateway.resource_group` | `string` | — | Resource group-navn |
| `gateway.public_ip_id` | `string` | — | Resource ID på en Standard public IP (udgående adresse) |
| `gateway.subnet_ids` | `list(string)` | `[]` | Subnet-ID'er der routes udgående gennem gateway'en |
| `gateway.idle_timeout_in_minutes` | `number` | `4` | SNAT idle timeout |
| `gateway.tags` | `map(string)` | `{}` | Tags på NAT gateway'en |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID på NAT gateway'en |
| `resource_guid` | Resource GUID på NAT gateway'en |
| `external_information` | Udgående public IP-ID + de tilknyttede subnets |
