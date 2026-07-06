# Security Group — Wrapper

Fælles indgangspunkt til at oprette en security group på enten **Azure** (NSG) eller **OVH** (OpenStack secgroup). Sæt enten `security_group.azure` eller `security_group.ovh` — aldrig begge.

## Usage

### OVH

```hcl
module "sg" {
  source = "./modules/network/security-group/wrapper"

  security_group = {
    name = "my-sg"
    ovh  = {}
    rules = [
      {
        name      = "allow-ssh"
        direction = "ingress"
        protocol  = "tcp"
        port      = "22"
        cidr      = "10.0.0.0/8"
      }
    ]
  }
}
```

### Azure

```hcl
module "sg" {
  source = "./modules/network/security-group/wrapper"

  security_group = {
    name = "my-nsg"
    azure = {
      location       = "westeurope"
      resource_group = "my-rg"
    }
    rules = [
      {
        name      = "allow-ssh"
        direction = "ingress"
        protocol  = "tcp"
        port      = "22"
        cidr      = "10.0.0.0/8"
      }
    ]
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `security_group.name` | `string` | — | Navn på security group'en |
| `security_group.azure` | `object` | `null` | Sæt til `{ location, resource_group }` for Azure |
| `security_group.ovh` | `object({})` | `null` | Sæt til `{}` for OVH |
| `security_group.tags` | `map(string)` | `{}` | Tags — Azure: NSG-tags; OVH: konverteres til `"key:value"`-strenge |
| `security_group.rules` | `list(object)` | `[]` | Liste af regler — se feltbeskrivelse nedenfor |

### Regel-felter

| Felt | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Unikt regelnavn |
| `direction` | `string` | — | `"ingress"` eller `"egress"` |
| `protocol` | `string` | — | `"tcp"`, `"udp"`, `"icmp"` eller `"*"` |
| `port` | `string` | `"*"` | Port eller range: `"80"`, `"8080-8090"`, `"*"` |
| `cidr` | `string` | `"*"` | Kilde- eller destination-CIDR. `"*"` = alle — oversættes automatisk på OVH (OpenStack kræver ellers gyldig CIDR) |
| `access` | `string` | `"Allow"` | Azure only: `"Allow"` eller `"Deny"`. **`"Deny"` afvises med en fejl når `ovh` er valgt** — OpenStack security groups er allow-only, og reglen ville ellers i stilhed blive en Allow |
| `priority` | `number` | `null` | Azure only: eksplicit NSG-prioritet. `null` = auto efter listeposition (100, 110, 120, …) — **bemærk:** med auto ændrer omrokering i listen prioriteterne; sæt eksplicit prioritet på regler hvor rækkefølgen betyder noget |
| `ethertype` | `string` | `"IPv4"` | OVH only: `"IPv4"` eller `"IPv6"` |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | ID på security group'en |
| `security_group_name` | Navn på security group'en |

## Brug i kontekst — knyt til en VM

### OVH

OVH's VM-modul tager security groups ved **navn** (`security_group_name`):

```hcl
module "sg" {
  source         = "./modules/network/security-group/wrapper"
  security_group = {
    name  = "web-sg"
    ovh   = {}
    rules = [
      { name = "ssh", direction = "ingress", protocol = "tcp", port = "22", cidr = "0.0.0.0/0" },
      { name = "https", direction = "ingress", protocol = "tcp", port = "443", cidr = "0.0.0.0/0" },
    ]
  }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "web"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id
    ovh = {
      project_id      = var.ovh_project_id
      image_name      = "Ubuntu 24.04"
      network_names   = [module.network.network_name]
      security_groups = [module.sg.security_group_name]
    }
  }
}
```

### Azure

Azure knytter en NSG til et NIC via `security_group_id` (`network_security_group_id`
pr. netværk i VM-modulet):

```hcl
module "sg" {
  source         = "./modules/network/security-group/wrapper"
  security_group = {
    name  = "web-sg"
    azure = { location = "westeurope", resource_group = "my-rg" }
    rules = [{ name = "https", direction = "ingress", protocol = "tcp", port = "443", cidr = "0.0.0.0/0", access = "Allow" }]
  }
}

module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "web"
    size           = "Standard_D2s_v3"
    location       = "westeurope"
    resource_group = "my-rg"
    azure = {
      networks = [{
        subnet_id                 = module.network.subnet_ids["default"]
        network_security_group_id = module.sg.security_group_id
      }]
      image = { publisher = "Canonical", offer = "0001-com-ubuntu-server-jammy", sku = "22_04-lts-gen2" }
    }
  }
}
```

> **Caveat:** `network_security_group_id` fodrer et `for_each`-filter i VM-modulet, så
> en *computed* NSG-id (oprettet i samme apply, som her) kan ramme Terraform/OpenTofu's
> unknown-value-`for_each`-begrænsning. Hvis det sker, kør et to-trins apply
> (`-target=module.sg` først), eller opret NSG'en i en tidligere apply. Se
> [`vm/azure` README](../../../vm/azure/README.md).
