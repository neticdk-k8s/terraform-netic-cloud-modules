# VM — Azure

Provisions a Linux or Windows virtual machine on Azure with a network interface, optional public IP, and auto-generated SSH key when none is provided.

## Resources created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `tls_private_key` | Linux + no `ssh_public_key` | 4096-bit RSA key |
| `azurerm_public_ip` | `create_public_ip = true` | Static Standard public IP |
| `azurerm_network_interface` | always | NIC attached to the given subnet |
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
    subnet_id        = module.network.subnet_ids["default"]
    create_public_ip = true
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
    subnet_id      = module.network.subnet_ids["default"]
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
    }
  }
}
```

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
| `subnet_id` | `string` | — | ID of the subnet to attach |
| `create_public_ip` | `bool` | `false` | Create and attach a public IP |
| `user_data` | `string` | `null` | Cloud-init script (Linux only, auto base64-encoded) |
| `image.publisher` | `string` | — | Image publisher |
| `image.offer` | `string` | — | Image offer |
| `image.sku` | `string` | — | Image SKU |
| `image.version` | `string` | `"latest"` | Image version |

## Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Name of the VM |
| `vm_ip` | Private IPv4 address |
| `public_ip` | Public IP (null if `create_public_ip = false`) |
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
