# VM — Azure

Provisions a Linux or Windows virtual machine on Azure with a network interface, optional public IP, and auto-generated SSH key when none is provided.

## Resources created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `tls_private_key` | Linux + no `ssh_public_key` | 4096-bit RSA key |
| `azurerm_public_ip` | `create_public_ip = true` | Static Standard public IP, attached to `networks[0]` |
| `azurerm_network_interface` | one per entry in `networks` | NIC attached to that subnet |
| `azurerm_network_interface_security_group_association` | per NIC with `network_security_group_id` set | Associates the NIC with an NSG |
| `azurerm_linux_virtual_machine` | `os_type = "Linux"` | Linux VM |
| `azurerm_windows_virtual_machine` | `os_type = "Windows"` | Windows VM |

## Usage

### Linux VM

```hcl
module "vm" {
  source = "./modules/vm/azure"

  vm = {
    name             = "my-server"
    size             = "Standard_D2s_v3"
    location         = "westeurope"
    resource_group   = "my-rg"
    create_public_ip = true
    networks = [{
      subnet_id                 = module.network.subnet_ids["default"]
      static_ip                 = null
      ip_forwarding             = false
      network_security_group_id = null
    }]
    image = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
    }
  }
}

output "ssh_private_key" { value = module.vm.ssh_private_key; sensitive = true }
output "public_ip"       { value = module.vm.public_ip }
```

### Windows VM

```hcl
module "vm" {
  source = "./modules/vm/azure"

  vm = {
    name           = "my-win-server"
    size           = "Standard_D4s_v3"
    location       = "westeurope"
    resource_group = "my-rg"
    os_type        = "Windows"
    admin_username = "adminuser"
    admin_pass     = var.admin_password
    networks = [{
      subnet_id                 = module.network.subnet_ids["default"]
      static_ip                 = null
      ip_forwarding             = false
      network_security_group_id = null
    }]
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
    }
  }
}
```

### Firewall/router VM with anti-spoofing disabled (`ip_forwarding`)

A VM that routes or forwards traffic which isn't addressed to its own IP (a firewall, NAT gateway or VPN endpoint like OPNsense) needs **IP forwarding** enabled on the NIC(s) that carry that traffic — otherwise Azure's fabric silently drops it, the same way OVH's Neutron anti-spoofing filter does.

```hcl
module "vm" {
  source = "./modules/vm/azure"

  vm = {
    name             = "opnsense-fw"
    size             = "Standard_D2s_v3"
    location         = "westeurope"
    resource_group   = "my-rg"
    create_public_ip = true

    networks = [
      {
        subnet_id                 = module.network.subnet_ids["public"] # networks[0]: primary NIC, gets the public IP
        static_ip                 = null
        ip_forwarding             = false
        network_security_group_id = null
      },
      {
        subnet_id                 = module.network.subnet_ids["private"]
        static_ip                 = "10.0.25.254"
        ip_forwarding             = true
        network_security_group_id = module.security_group.id
      },
    ]
    image = {
      publisher = "..."
      offer     = "..."
      sku       = "..."
    }
  }
}
```

**Unlike OVH**, `ip_forwarding = true` here only tells Azure's fabric to allow the NIC to send/receive traffic for IPs other than its own — it does **not** disable the Network Security Group. NSG rules are enforced independently and must separately permit the forwarded traffic (e.g. allow the VPN remote subnet). Attach the NSG via `network_security_group_id` on the relevant network entry.

## Inputs

### `vm`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | VM name |
| `size` | `string` | — | Azure VM size (e.g. `"Standard_D2s_v3"`) |
| `location` | `string` | — | Azure region |
| `resource_group` | `string` | — | Existing resource group |
| `os_type` | `string` | `"Linux"` | `"Linux"` or `"Windows"` |
| `admin_username` | `string` | `"azureuser"` | Administrator username |
| `admin_pass` | `string` | `null` | Administrator password — required for Windows |
| `ssh_public_key` | `string` | `null` | SSH public key — leave `null` to auto-generate |
| `networks` | `list(object)` | `[]` | NICs to attach, in order — see below. Must contain at least one entry |
| `create_public_ip` | `bool` | `false` | Create a public IP and attach it to `networks[0]` |
| `user_data` | `string` | `null` | Cloud-init script (Linux only, auto base64-encoded) |
| `image.publisher` | `string` | — | Image publisher |
| `image.offer` | `string` | — | Image offer |
| `image.sku` | `string` | — | Image SKU |
| `image.version` | `string` | `"latest"` | Image version |

### `vm.networks[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `subnet_id` | `string` | — | ID of the subnet to attach this NIC to |
| `static_ip` | `string` | none — pass `null` explicitly | Fixed private IP — pass `null` for dynamic allocation |
| `ip_forwarding` | `bool` | none — pass `false` explicitly | Enables IP forwarding on this NIC — required for firewall/router/VPN VMs that forward traffic not addressed to their own IP. Does **not** disable NSG enforcement (unlike OVH's `ip_forwarding`) |
| `network_security_group_id` | `string` | none — pass `null` explicitly | NSG to associate with this NIC |

**Every field must be present in each `networks[]` entry** (use `null`/`false` for the ones that don't apply) — these are intentionally not `optional()` in the type constraint, to avoid a Terraform/OpenTofu limitation where optional-attribute default-filling turns a partially-unknown object (e.g. a `subnet_id` created in the same apply) wholly unknown, breaking `for_each` downstream.

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Name of the VM |
| `vm_ip` | Private IPv4 address of the primary NIC (`networks[0]`) |
| `public_ip` | Public IP (null if `create_public_ip = false`) |
| `network_interface_ids` | IDs of all NICs, in the same order as `networks` |
| `ssh_private_key` | Generated PEM key *(sensitive)* — null if `ssh_public_key` was provided |

## Common image references

| OS | publisher | offer | sku |
|----|-----------|-------|-----|
| Ubuntu 22.04 | `Canonical` | `0001-com-ubuntu-server-jammy` | `22_04-lts-gen2` |
| Ubuntu 24.04 | `Canonical` | `ubuntu-24_04-lts` | `server` |
| Windows Server 2022 | `MicrosoftWindowsServer` | `WindowsServer` | `2022-datacenter-azure-edition` |
| Windows Server 2019 | `MicrosoftWindowsServer` | `WindowsServer` | `2019-datacenter` |

## Notes

- **OS disk** is always `Premium_LRS` with `ReadWrite` caching. Adjust in the module if needed.
- **`source_image_reference` changes are ignored** after creation to prevent accidental VM replacement on minor image updates.
- **`user_data`** is automatically base64-encoded before passing to Azure. Pass the raw cloud-init string.
- **`ssh_private_key` output** — store it securely; it is in Terraform state.
