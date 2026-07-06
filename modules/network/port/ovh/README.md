# Network port — OVHcloud

Creates a single port on an existing OVH/OpenStack private network. Its main
purpose is to allow **disabling port security** (`ip_forwarding = true`) so a VM
can route/forward traffic that isn't addressed to its own IP — e.g. a firewall,
NAT gateway or VPN endpoint like OPNsense. Without this, OVH's Neutron
anti-spoofing filter silently drops the forwarded packets.

OVH-only — OpenStack ports have no Azure equivalent (on Azure, IP forwarding is a
property of the VM's NIC and lives in the `vm` module instead). There is
therefore no wrapper and no Azure implementation.

## Resources created

| Resource | Description |
|----------|-------------|
| `openstack_networking_port_v2` | One network port, optionally with a fixed IP and port security disabled |

## Usage

Call once per port. Use `for_each` in the caller keyed on a **static** value
(the network name) and pass the computed `network_id` / `subnet_id` in as
values — this keeps `for_each` keys known at plan time and lets everything run
in a single apply.

```hcl
module "network" {
  source   = ".../modules/network/network/wrapper"
  for_each = { for n in var.networks : n.name => n }
  network  = { name = each.value.name, ovh = { ... } }
}

module "port" {
  source   = ".../modules/network/port/ovh"
  for_each = { for n in var.networks : n.name => n }

  port = {
    name          = "${each.value.name}-opnsense-port"
    network_id    = module.network[each.key].network_id
    subnet_id     = module.network[each.key].subnet_ids[each.value.regions[0].region]
    static_ip     = cidrhost(each.value.regions[0].subnet, 254)
    ip_forwarding = true
  }
}

module "opnsense" {
  source = ".../modules/vm/wrapper"
  vm = {
    # ...
    ovh = {
      # ...
      port_ids = [for p in module.port : p.id]
    }
  }
}
```

## Inputs

### `port`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Port name |
| `network_id` | `string` | — | OpenStack UUID of the network (e.g. `module.network.network_id`) |
| `subnet_id` | `string` | `null` | OpenStack subnet UUID — required if `static_ip` is set |
| `static_ip` | `string` | `null` | Fixed IP to assign (e.g. `x.x.x.254`) |
| `ip_forwarding` | `bool` | `false` | When `true`, sets `port_security_enabled = false` — disables **both** anti-spoofing **and** security groups on the port |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Port UUID — pass to a VM via `vm.ovh.port_ids` |
| `ip_address` | Fixed IP, **IPv4 preferred** (an Ext-Net port often gets both v4 and v6) — null if none |
| `ipv4_address` | First IPv4 fixed IP (null if none) |
| `ipv6_address` | First IPv6 fixed IP (null if none) |
| `mac_address` | MAC address of the port — match it against the guest's interfaces to verify vtnetN ordering |

## Notes

- **`ip_forwarding = true` is a broad bypass** — there's no way in OpenStack to
  keep security groups active while allowing forwarded/spoofed traffic. Only use
  it on the port(s) that actually need to carry forwarded traffic.
- **`for_each` keys must be static.** Never key the caller's `for_each` on
  `network_id` or another computed value — key on the network name (or another
  config-known string) and pass computed IDs as map values.
