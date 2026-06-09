# Public IP — OVH

Reserverer en floating IP fra OVH's `Ext-Net`-pool med valgfri `prevent_destroy`-beskyttelse (default: `false`).

## Usage

```hcl
module "pip" {
  source = "./modules/network/public-ip/ovh"

  public_ip = {
    name            = "my-fip"
    location        = "GRA11"
    resource_group  = var.ovh_project_id
    prevent_destroy = true
  }
}

output "ip" { value = module.pip.ip_address }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `public_ip.name` | `string` | — | Navn (bruges som tag) |
| `public_ip.location` | `string` | — | OVH-region (f.eks. `"GRA11"`) |
| `public_ip.resource_group` | `string` | — | OVH project ID / service name |
| `public_ip.prevent_destroy` | `bool` | `false` | Beskyt mod utilsigtet sletning |
| `public_ip.tags` | `map(string)` | `{}` | Tags på ressourcen |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den reserverede floating IP-adresse |
| `id` | Floating IP ID (bruges ved association med en VM-port) |
