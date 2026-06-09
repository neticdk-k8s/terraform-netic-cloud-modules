# Security Group — OVH

Opretter en OpenStack security group (`openstack_networking_secgroup_v2`) med regler via Neutron API.

## Usage

```hcl
module "sg" {
  source = "./modules/network/security-group/ovh"

  security_group = {
    name = "my-sg"
    rules = [
      {
        name      = "allow-ssh"
        direction = "ingress"
        protocol  = "tcp"
        port      = "22"
        cidr      = "10.0.0.0/8"
      },
      {
        name      = "allow-all-egress"
        direction = "egress"
        protocol  = "*"
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
| `protocol` | `string` | — | `"tcp"`, `"udp"`, `"icmp"` eller `"*"` (alle) |
| `port` | `string` | `"*"` | Port eller range: `"80"`, `"8080-8090"`, `"*"` |
| `cidr` | `string` | `"0.0.0.0/0"` | Remote IP-prefix |
| `ethertype` | `string` | `"IPv4"` | `"IPv4"` eller `"IPv6"` |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | OpenStack security group ID |
| `security_group_name` | Navn på security group'en |
