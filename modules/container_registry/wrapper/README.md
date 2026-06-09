# Container Registry — Wrapper

Deploys a managed container registry to either **OVHcloud** or **Azure** using a shared interface.

## Usage

### OVHcloud

```hcl
module "registry" {
  source         = "./modules/container_registry/wrapper"
  cloud_provider = "ovh"

  container_registry = {
    deploy = true
    name   = "my-registry"
  }

  ovh_config = {
    project_id = var.ovh_project_id
    region     = "GRA"
  }

  registry_users = [
    { login = "ci-user", email = "ci@example.com" }
  ]
}
```

### Azure

```hcl
module "registry" {
  source         = "./modules/container_registry/wrapper"
  cloud_provider = "azure"

  container_registry = {
    deploy = true
    name   = "myregistry"   # globally unique
  }

  azure_config = {
    location       = "westeurope"
    resource_group = "my-rg"
    sku            = "Premium"
  }

  ip_restrictions = [
    { ip_block = "203.0.113.0/24", description = "Office" }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `cloud_provider` | `string` | yes | `"ovh"` or `"azure"` |
| `container_registry` | `object` | yes | `{ deploy, name }` |
| `registry_users` | `list(object)` | no | `[{ login, email }]` |
| `ip_restrictions` | `list(object)` | no | `[{ ip_block, description }]` |
| `ovh_config` | `object` | if OVH | `{ project_id, region }` |
| `azure_config` | `object` | if Azure | `{ location, resource_group, sku? }` |

## Outputs

| Name | Description |
|------|-------------|
| `registry_url` | URL / login server of the registry |
| `user_passwords` | Map of usernames → passwords *(sensitive)* |

## Notes

- Azure IP restrictions require `sku = "Premium"` in `azure_config`.
- OVHcloud does not support IAM and local users simultaneously — this wrapper uses local users.
