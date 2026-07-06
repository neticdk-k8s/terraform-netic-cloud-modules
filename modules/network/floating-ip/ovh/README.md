# Floating IP — OVH

Reserverer en **floating IP** fra OVH's `Ext-Net`-pool med valgfri
`prevent_destroy`-beskyttelse (default: `false`).

En floating IP er en **NAT'et** offentlig IP: den knyttes til en port på et
privat net og NAT'es (DNAT/SNAT) ind til porten. Skal den offentlige IP i stedet
sidde *direkte* på et interface (fx en firewall/OPNsense WAN), er en floating IP
ikke det rigtige — lav i stedet en port direkte på `Ext-Net` (se
[`network/port/ovh`](../../port/ovh)), eller brug en Additional IP
(se [`network/public-ip`](../../public-ip)).

> Azure har ingen floating-IP-pendant, så dette modul findes kun for OVH og har
> derfor ingen `wrapper`.

## Usage

```hcl
module "fip" {
  source = "./modules/network/floating-ip/ovh"

  floating_ip = {
    name            = "my-fip"
    resource_group  = var.ovh_project_id
    prevent_destroy = true
  }
}

output "ip" { value = module.fip.ip_address }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `floating_ip.name` | `string` | — | Navn (bruges som tag/description) |
| `floating_ip.resource_group` | `string` | — | OVH project ID / service name |
| `floating_ip.prevent_destroy` | `bool` | `false` | Beskyt mod utilsigtet sletning |
| `floating_ip.tags` | `map(string)` | `{}` | Tags på ressourcen |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den reserverede floating IP-adresse |
| `id` | Floating IP ID (bruges ved association med en VM-port) |

## Knyt floating IP'en til en VM's port

```hcl
resource "openstack_networking_floatingip_associate_v2" "web" {
  floating_ip = module.fip.ip_address
  port_id     = module.port.id
}
```
