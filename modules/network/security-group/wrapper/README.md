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
| `security_group.rules` | `list(object)` | `[]` | Liste af regler — se feltbeskrivelse nedenfor |

### Regel-felter

| Felt | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Unikt regelnavn |
| `direction` | `string` | — | `"ingress"` eller `"egress"` |
| `protocol` | `string` | — | `"tcp"`, `"udp"`, `"icmp"` eller `"*"` |
| `port` | `string` | `"*"` | Port eller range: `"80"`, `"8080-8090"`, `"*"` |
| `cidr` | `string` | `"*"` | Kilde- eller destination-CIDR |
| `access` | `string` | `"Allow"` | Azure only: `"Allow"` eller `"Deny"` |
| `ethertype` | `string` | `"IPv4"` | OVH only: `"IPv4"` eller `"IPv6"` |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | ID på security group'en |
| `security_group_name` | Navn på security group'en |
