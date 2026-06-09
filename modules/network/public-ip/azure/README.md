# Public IP — Azure

Opretter en statisk Standard public IP i Azure med valgfri `prevent_destroy`-beskyttelse (default: `true`).

## Usage

```hcl
module "pip" {
  source = "./modules/network/public-ip/azure"

  public_ip = {
    name           = "my-pip"
    location       = "westeurope"
    resource_group = "my-rg"
  }
}

output "ip"    { value = module.pip.ip_address }
output "pip_id" { value = module.pip.id }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `public_ip.name` | `string` | — | Navn på public IP-ressourcen |
| `public_ip.location` | `string` | — | Azure-region (f.eks. `"westeurope"`) |
| `public_ip.resource_group` | `string` | — | Resource group-navn |
| `public_ip.prevent_destroy` | `bool` | `true` | Beskyt mod utilsigtet sletning |
| `public_ip.tags` | `map(string)` | `{}` | Tags på ressourcen |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den tildelte public IP-adresse |
| `id` | Resource ID (bruges ved tilknytning til NIC) |
