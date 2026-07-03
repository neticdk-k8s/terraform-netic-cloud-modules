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

## Brug i kontekst — knyt IP'en til en VM

Dette modul *reserverer* kun en public IP (nyttigt når du vil have en stabil
adresse der overlever at VM'en genskabes — se `prevent_destroy`). Selve
tilknytningen sker forskelligt på de to clouds.

### OVH — floating IP på en VM's port (NAT)

På OVH er en public IP fra dette modul en **floating IP**, som NAT'es ind til en
port på et privat net. Opret porten (via `network/port/ovh`), knyt den offentlige
IP til porten, og giv porten til VM'en:

```hcl
module "pip" {
  source    = "./modules/network/public-ip/wrapper"
  public_ip = { name = "web-fip", location = "GRA11", resource_group = var.ovh_project_id, ovh = {} }
}

module "network" {
  source  = "./modules/network/network/wrapper"
  network = { name = "web-net", ovh = { project_id = var.ovh_project_id, vlan_id = 100, regions = [{ region = "GRA11", subnet = "10.0.0.0/24" }] } }
}

module "port" {
  source = "./modules/network/port/ovh"
  port   = { name = "web-port", network_id = module.network.network_id, subnet_id = module.network.subnet_ids["GRA11"] }
}

# Knyt den reserverede floating IP til VM'ens port
resource "openstack_networking_floatingip_associate_v2" "web" {
  floating_ip = module.pip.ip_address
  port_id     = module.port.id
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "web"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id
    ovh            = { project_id = var.ovh_project_id, image_name = "Ubuntu 24.04", port_ids = [module.port.id] }
  }
}
```

> **Bemærk:** Skal VM'en have den offentlige IP *direkte* på sit interface (fx en
> firewall/OPNsense's WAN), skal du **ikke** bruge dette modul — lav i stedet en
> port direkte på `Ext-Net` (se [`network/port/ovh`](../../port/ovh)). Floating IP
> = NAT ind til privat net; Ext-Net-port = public IP direkte på NIC'en.

### Azure — knyt til et netværkskort

`vm/wrapper`'s Azure-side opretter selv en public IP via `create_public_ip = true`.
Brug dette modul når du i stedet vil styre IP'en separat (fx en fast IP der
genbruges, eller en IP til en load balancer) og selv knytte den til et NIC:

```hcl
module "pip" {
  source    = "./modules/network/public-ip/wrapper"
  public_ip = { name = "web-pip", location = "westeurope", resource_group = "my-rg", azure = {} }
}

resource "azurerm_network_interface" "web" {
  name                = "web-nic"
  location            = "westeurope"
  resource_group_name = "my-rg"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.subnet_ids["default"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = module.pip.id
  }
}
```
