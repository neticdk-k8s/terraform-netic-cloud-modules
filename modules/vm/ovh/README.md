# VM — OVHcloud

Provisions a virtual machine on OVHcloud via OpenStack. Supports both Linux and Windows images. Automatically generates an SSH key pair when no key is supplied for Linux VMs.

## Resources created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `tls_private_key` | Linux + no `sshkey` supplied | 4096-bit RSA key pair |
| `openstack_compute_keypair_v2` | Linux + no `sshkey` supplied | Registers the public key with OpenStack |
| `ovh_cloud_project_ssh_key` | Linux + no `sshkey` supplied | Registers the public key with OVH |
| `openstack_networking_port_v2` | per network with `static_ip` and/or `ip_forwarding` | Dedicated port for that network attachment |
| `openstack_compute_instance_v2` | always | The virtual machine (Linux or Windows variant) |

## Usage

### Linux VM with auto-generated SSH key

```hcl
module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name          = "my-server"
    size          = "b2-7"
    image_name    = "Ubuntu 24.04"
    create_public_ip = true
    networks         = [{ name = "my-private-network" }]
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

### Firewall/router VM with anti-spoofing disabled (`ip_forwarding`)

A VM that routes or forwards traffic which isn't addressed to its own IP (a firewall, NAT gateway or VPN endpoint like OPNsense) needs a dedicated port with a static IP and OpenStack's port security disabled — otherwise OVH's Neutron anti-spoofing filter silently drops the forwarded packets.

```hcl
module "vm" {
  source = "./modules/vm/ovh"

  ovh_project_id = var.ovh_project_id

  vm = {
    name             = "opnsense-fw"
    size             = "b2-7"
    image_name       = "opnsense"
    create_public_ip = true

    networks = [{
      name          = "my-private-network"
      network_id    = module.network.network_id           # from modules/network/ovh
      subnet_id     = module.network.subnet_ids["GRA11"]
      static_ip     = "10.0.25.254"
      ip_forwarding = true
    }]
  }
}
```

`ip_forwarding = true` sets `port_security_enabled = false` on that port. **This disables both anti-spoofing and security groups on the port** — there's no way to keep security groups active while allowing spoofed/forwarded traffic in OpenStack. Only set it on the network(s) that actually need to carry forwarded traffic.

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `ovh_project_id` | `string` | OVH Public Cloud project ID |
| `vm` | `object` | VM configuration (see below) |

### `vm`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | VM name |
| `size` | `string` | — | OVH flavor (e.g. `"b2-7"`, `"b2-15"`) |
| `image_name` | `string` | — | OS image name — if it contains "windows" (case-insensitive) a Windows VM is created |
| `sshkey` | `string` | `null` | Name of an existing OVH keypair — leave `null` to auto-generate |
| `admin_pass` | `string` | `null` | Administrator password — **required for Windows VMs** |
| `networks` | `list(object)` | `[]` | Private networks to attach — see below. `Ext-Net` must not be listed here; use `create_public_ip` instead |
| `power_state` | `string` | `"active"` | `"active"` or `"shutoff"` |
| `user_data` | `string` | `null` | Cloud-init user data script |

### `vm.networks[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Network name |
| `network_id` | `string` | `null` | OpenStack network UUID — required if `static_ip` or `ip_forwarding` is set |
| `subnet_id` | `string` | `null` | OpenStack subnet UUID — required if `static_ip` is set |
| `static_ip` | `string` | `null` | Fixed IP to assign on this network |
| `ip_forwarding` | `bool` | `false` | Disables OpenStack port security (anti-spoofing **and** security groups) on this port — required for firewall/router/VPN VMs that forward traffic not addressed to their own IP |

If neither `static_ip` nor `ip_forwarding` is set, the network attaches by name with DHCP and normal port security (the previous, simple behaviour). Setting either one creates a dedicated `openstack_networking_port_v2` for that network instead.

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Name of the created VM |
| `vm_ip` | Primary IPv4 address |
| `public_ip` | Public IP from `Ext-Net` (null if Ext-Net is not attached) |
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

## Notes

- **Windows detection** is based on a case-insensitive regex match on `image_name`. Any image name containing "windows" is treated as a Windows VM.
- **`admin_pass`** must always be set for Windows VMs — Terraform will fail with a `precondition` error if it is missing.
- **`image_name` changes are ignored** after creation (`lifecycle.ignore_changes`) to prevent accidental replacement when OVH releases a new patch image.
- **`ssh_private_key` output** — store it securely (e.g. in Vault or a secrets manager). It is marked `sensitive` and will not appear in plan output, but it is stored in Terraform state.
