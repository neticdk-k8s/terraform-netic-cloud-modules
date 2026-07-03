# VM — OVHcloud

Provisions a virtual machine on OVHcloud via OpenStack. Supports both Linux and Windows images. Automatically generates an SSH key pair when no key is supplied for Linux VMs.

## Resources created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `tls_private_key` | Linux + no `sshkey` supplied | 4096-bit RSA key pair |
| `openstack_compute_keypair_v2` | Linux + no `sshkey` supplied | Registers the public key with OpenStack |
| `ovh_cloud_project_ssh_key` | Linux + no `sshkey` supplied | Registers the public key with OVH |
| `openstack_compute_instance_v2` | always | The virtual machine (Linux or Windows variant) |
| `openstack_compute_volume_attach_v2` | per entry in `disk_ids` | Data disk attachment |

## Usage

### Linux VM with auto-generated SSH key

```hcl
module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name             = "my-server"
    size             = "b2-7"
    image_name       = "Ubuntu 24.04"
    create_public_ip = true
    network_names    = ["my-private-network"]
  }
}

output "ssh_private_key" {
  value     = module.vm.ssh_private_key
  sensitive = true
}
```

### Linux VM with an existing SSH key

```hcl
module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name             = "my-server"
    size             = "b2-7"
    image_name       = "Ubuntu 24.04"
    sshkey           = "my-existing-keypair-name"
    create_public_ip = true
  }
}
```

### Windows VM

```hcl
module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name             = "my-windows-server"
    size             = "b2-15"
    image_name       = "Windows Server 2022"
    admin_pass       = var.admin_password
    create_public_ip = true
  }
}
```

### Firewall/router VM with anti-spoofing disabled

A VM that routes or forwards traffic which isn't addressed to its own IP (a firewall, NAT gateway or VPN endpoint like OPNsense) needs a port with OpenStack's port security disabled — otherwise OVH's Neutron anti-spoofing filter silently drops the forwarded packets.

That port is **not** created here — create it with [`modules/network/port/ovh`](../../network/port/ovh) (which sets `port_security_enabled = false` via `ip_forwarding = true`) and pass its ID in via `port_ids`:

```hcl
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

module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name             = "opnsense-fw"
    size             = "b2-7"
    image_name       = "opnsense"
    create_public_ip = true
    port_ids         = [for p in module.port : p.id]
  }
}
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `ovh_project_id` | `string` | OVH Public Cloud project ID |
| `vm` | `object` | VM configuration (see below) |

### `vm`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | VM name |
| `resource_group` | `string` | — | Only used as a metadata tag (grouping convention) — not an OVH resource |
| `size` | `string` | — | OVH flavor (e.g. `"b2-7"`, `"b2-15"`) |
| `image_name` | `string` | — | OS image name — if it contains "windows" (case-insensitive) a Windows VM is created |
| `sshkey` | `string` | `null` | Name of an existing OVH keypair — leave `null` to auto-generate |
| `admin_pass` | `string` | `null` | Administrator password — **required for Windows VMs** |
| `network_names` | `list(string)` | `[]` | Networks to attach by name (DHCP, port security enabled). `Ext-Net` must not be listed here; use `create_public_ip` instead |
| `port_ids` | `list(string)` | `[]` | Pre-created port UUIDs to attach (e.g. from [`modules/network/port/ovh`](../../network/port/ovh)) — used for static IPs and/or disabled port security |
| `disk_ids` | `list(string)` | `[]` | Pre-created volume UUIDs to attach as data disks (from [`modules/storage/disk/ovh`](../../storage/disk/ovh)) |
| `os_disk` | `object` | `null` | Boot from a volume with chosen size/type: `{ size_gb, volume_type? }`. **Use a flex flavor** (e.g. `"b2-7-flex"`) — non-flex flavors already include and bill their full local disk |
| `power_state` | `string` | `"active"` | `"active"` or `"shutoff"` |
| `user_data` | `string` | `null` | Cloud-init user data script |

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Name of the created VM |
| `vm_ip` | Primary IPv4 address |
| `public_ip` | Public IP from `Ext-Net` — **only when attached by name** (`create_public_ip`). Null when the WAN is attached via `port_ids` (e.g. an Ext-Net port); read the IP from the port module's `ip_address` output instead |
| `ssh_private_key` | Generated private key in PEM format *(sensitive)* — null if `sshkey` was provided |

## Provider

```hcl
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "openstack" {
  auth_url  = "https://auth.cloud.ovh.net/v3"
  tenant_id = var.ovh_project_id
  user_name = var.openstack_user
  password  = var.openstack_password
  region    = "GRA11"
}
```

### Custom OS disk size/type (flex flavor)

OVH flavors have a fixed local disk. To choose your own OS disk size/type, pick a
*flex* flavor (small 50 GB local disk, cheaper) and set `os_disk` — the VM then
boots from a volume instead:

```hcl
vm = {
  name       = "big-disk-vm"
  size       = "b2-7-flex"
  image_name = "Ubuntu 24.04"
  os_disk    = { size_gb = 500, volume_type = "high-speed" }
}
```

## Notes

- **Data disk attachments are index-based** (`count`) — removing a disk from the middle of `disk_ids` re-attaches the ones after it. Append new disks at the end.
- **Windows detection** is based on a case-insensitive regex match on `image_name`. Any image name containing "windows" is treated as a Windows VM.
- **`admin_pass`** must always be set for Windows VMs — Terraform will fail with a `precondition` error if it is missing.
- **`image_name` changes are ignored** after creation (`lifecycle.ignore_changes`) to prevent accidental replacement when OVH releases a new patch image.
- **`ssh_private_key` output** — store it securely (e.g. in Vault or a secrets manager). It is marked `sensitive` and will not appear in plan output, but it is stored in Terraform state.
