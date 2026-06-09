# Security Group — Azure

Opretter en Azure Network Security Group (NSG) med regler. Priority tildeles automatisk (100, 110, 120 …) baseret på listens rækkefølge.

## Usage

```hcl
module "sg" {
  source = "./modules/network/security-group/azure"

  security_group = {
    name           = "my-nsg"
    location       = "westeurope"
    resource_group = "my-rg"
    rules = [
      {
        name      = "allow-ssh"
        direction = "ingress"
        protocol  = "tcp"
        port      = "22"
        cidr      = "10.0.0.0/8"
      },
      {
        name      = "allow-https"
        direction = "ingress"
        protocol  = "tcp"
        port      = "443"
        cidr      = "*"
      }
    ]
  }
}
```

## Regel-felter

| Felt | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Unikt regelnavn |
| `direction` | `string` | — | `"ingress"` eller `"egress"` |
| `protocol` | `string` | — | `"tcp"`, `"udp"`, `"icmp"` eller `"*"` |
| `port` | `string` | `"*"` | Port eller range: `"80"`, `"8080-8090"`, `"*"` |
| `cidr` | `string` | `"*"` | Kilde-CIDR (ingress) eller destination-CIDR (egress) |
| `access` | `string` | `"Allow"` | `"Allow"` eller `"Deny"` |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | ID på NSG'en |
| `security_group_name` | Navn på NSG'en |
