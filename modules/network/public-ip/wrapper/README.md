# Public IP — Wrapper

Fælles indgangspunkt til en **direkte tildelt public IP** på enten **Azure** eller
**OVH**. Sæt enten `public_ip.azure` eller `public_ip.ovh` — aldrig begge.

> **De to providere fungerer forskelligt:**
> - **Azure** *opretter* en helt ny public IP (`azurerm_public_ip`).
> - **OVH** *attacher* en **forudbestilt** Additional IP (failover IP) til en instans
>   — du skal selv angive `ip` (den forudbestilte adresse) og `routed_to`
>   (instansens GUID). Modulet opretter altså ikke IP'en.
>
> Skal du have en OVH **NAT'et floating IP** i stedet, brug det separate modul
> [`network/floating-ip/ovh`](../../floating-ip/ovh) (findes kun for OVH).

## Usage

### Azure — opretter en ny public IP

```hcl
module "pip" {
  source = "./modules/network/public-ip/wrapper"

  public_ip = {
    azure = {
      name           = "my-pip"
      location       = "westeurope"
      resource_group = "my-rg"
    }
  }
}

output "ip" { value = module.pip.ip_address }
```

### OVH — attacher en forudbestilt Additional IP

```hcl
module "pip" {
  source = "./modules/network/public-ip/wrapper"

  public_ip = {
    ovh = {
      service_name = var.ovh_project_id
      ip           = "203.0.113.10"
      routed_to    = module.vm.instance_id
    }
  }
}

output "ip" { value = module.pip.ip_address }
```

## Inputs

Sæt præcis ét af `public_ip.azure` / `public_ip.ovh`.

### `public_ip.azure`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Navn på public IP-ressourcen |
| `location` | `string` | — | Azure-region (f.eks. `"westeurope"`) |
| `resource_group` | `string` | — | Resource group-navn |
| `prevent_destroy` | `bool` | `true` | Beskyt mod utilsigtet sletning |
| `tags` | `map(string)` | `{}` | Tags på ressourcen |

### `public_ip.ovh`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `service_name` | `string` | — | OVH public cloud project ID (ovh_project_id) |
| `ip` | `string` | — | Den forudbestilte Additional IP-adresse |
| `routed_to` | `string` | — | GUID på instansen IP'en skal routes til |
| `prevent_destroy` | `bool` | `false` | Beskyt mod utilsigtet detach |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den tildelte/attachede IP-adresse |
| `id` | Ressource ID (Additional IP-blok ID for OVH, resource ID for Azure) |

## Brug i kontekst — knyt IP'en til en VM

### Azure — knyt til et netværkskort

Dette modul opretter en selvstændig public IP (nyttigt til en fast IP der genbruges,
eller en IP til en load balancer) som du selv knytter til et NIC:

```hcl
module "pip" {
  source    = "./modules/network/public-ip/wrapper"
  public_ip = { azure = { name = "web-pip", location = "westeurope", resource_group = "my-rg" } }
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

### OVH — Additional IP routet direkte til en instans

En OVH Additional IP sidder direkte på instansen (til forskel fra en floating IP,
der NAT'es). IP-blokken skal være bestilt hos OVH i forvejen; her routes den blot til
instansen:

```hcl
module "pip" {
  source    = "./modules/network/public-ip/wrapper"
  public_ip = { ovh = { service_name = var.ovh_project_id, ip = "203.0.113.10", routed_to = module.vm.instance_id } }
}
```

> **Skal du bruge en NAT'et IP i stedet?** Se
> [`network/floating-ip/ovh`](../../floating-ip/ovh) (floating IP = NAT ind til en
> port på et privat net).
