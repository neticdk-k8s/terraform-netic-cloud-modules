# Container Registry — Azure (ACR)

Provisions an Azure Container Registry with optional IP restrictions and per-user tokens.

## Resources created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `azurerm_container_registry` | `deploy = true` | The container registry |
| `azurerm_container_registry_scope_map` | `deploy = true` + users exist | Shared read/write scope for all tokens |
| `azurerm_container_registry_token` | per user | One token per registry user |
| `azurerm_container_registry_token_password` | per user | Generated password per token |

## Usage

```hcl
module "registry" {
  source = "./modules/container_registry/azure"

  container_registry = {
    deploy         = true
    name           = "myregistry"        # globally unique, 5-50 alphanumeric chars
    location       = "westeurope"
    resource_group = "my-resource-group"
    sku            = "Premium"           # Premium required for ip_restrictions
  }

  registry_users = [
    { login = "ci-user",  email = "ci@example.com" },
    { login = "dev-user", email = "dev@example.com" }
  ]

  ip_restrictions = [
    { ip_block = "203.0.113.0/24", description = "Office network" }
  ]
}

output "registry_url"    { value = module.registry.registry_url }
output "user_passwords"  { value = module.registry.user_passwords; sensitive = true }
```

## Inputs

### `container_registry`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `deploy` | `bool` | — | Set to `false` to skip all resource creation |
| `name` | `string` | — | Registry name — globally unique, 5-50 alphanumeric chars |
| `location` | `string` | — | Azure region |
| `resource_group` | `string` | — | Existing resource group |
| `sku` | `string` | `"Basic"` | `"Basic"`, `"Standard"`, or `"Premium"` |

### `registry_users` list entry

| Field | Type | Description |
|-------|------|-------------|
| `login` | `string` | Token / username |
| `email` | `string` | Email (used for reference only in Azure) |

### `ip_restrictions` list entry

| Field | Type | Description |
|-------|------|-------------|
| `ip_block` | `string` | CIDR to allow |
| `description` | `string` | Label for the rule |

## Outputs

| Name | Description |
|------|-------------|
| `registry_url` | Login server (e.g. `myregistry.azurecr.io`) |
| `admin_username` | Admin username |
| `admin_password` | Admin password *(sensitive)* |
| `user_passwords` | Map of token usernames → generated passwords *(sensitive)* |

## Notes

- **IP restrictions require Premium SKU** — applying `ip_restrictions` on Basic or Standard will cause an API error.
- **Admin credentials** — `admin_enabled = true` is set by default. Use `admin_username` / `admin_password` outputs for simple tooling, and token-based credentials for CI systems.
- **Token passwords** are generated once. They cannot be retrieved again without recreating the password resource.
