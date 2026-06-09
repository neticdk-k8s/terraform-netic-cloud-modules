# Public IP — Wrapper

Fælles indgangspunkt til at reservere en public IP på enten **Azure** eller **OVH**. Sæt enten `public_ip.azure` eller `public_ip.ovh` — aldrig begge.

## Usage

### OVH

```hcl
module "pip" {
  source = "./modules/network/public-ip/wrapper"

  public_ip = {
    name           = "my-fip"
    location       = "GRA11"
    resource_group = var.ovh_project_id
    ovh            = {}
  }
}
```

### Azure

```hcl
module "pip" {
  source = "./modules/network/public-ip/wrapper"

  public_ip = {
    name           = "my-pip"
    location       = "westeurope"
    resource_group = "my-rg"
    azure          = {}
  }
}

output "ip" { value = module.pip.ip_address }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `public_ip.name` | `string` | — | Navn på ressourcen |
| `public_ip.location` | `string` | — | Region/location |
| `public_ip.resource_group` | `string` | — | Resource group (Azure) eller OVH project ID |
| `public_ip.prevent_destroy` | `bool` | `false` | Beskyt mod utilsigtet sletning |
| `public_ip.tags` | `map(string)` | `{}` | Tags |
| `public_ip.azure` | `object({})` | `null` | Sæt til `{}` for at vælge Azure |
| `public_ip.ovh` | `object({})` | `null` | Sæt til `{}` for at vælge OVH |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den tildelte/reserverede IP-adresse |
| `id` | Ressource ID (floating IP ID for OVH, resource ID for Azure) |
