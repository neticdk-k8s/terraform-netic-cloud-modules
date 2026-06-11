# Container Registry — Wrapper

Deploys a managed container registry to either **OVHcloud** or **Azure** using a shared interface.

The target provider is selected by setting exactly one of `container_registry.ovh` or `container_registry.azure`.

## Usage

### OVHcloud

```hcl
module "registry" {
  source = "./modules/container_registry/wrapper"

  container_registry = {
    deploy = true
    name   = "my-registry"

    ovh = {
      project_id = var.ovh_project_id
      region     = "GRA"
    }
  }

  registry_users = [
    { login = "ci-user", email = "ci@example.com" }
  ]
}
```

### Azure

```hcl
module "registry" {
  source = "./modules/container_registry/wrapper"

  container_registry = {
    deploy = true
    name   = "myregistry" # globally unique

    azure = {
      location       = "westeurope"
      resource_group = "my-rg"
      sku            = "Premium"
    }
  }

  ip_restrictions = [
    { ip_block = "203.0.113.0/24", description = "Office" }
  ]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `container_registry` | `object` | yes | `{ deploy, name, ovh?, azure? }` — set exactly one of `ovh` / `azure` |
| `container_registry.ovh` | `object` | if OVH | `{ project_id, region }` |
| `container_registry.azure` | `object` | if Azure | `{ location, resource_group, sku? }` |
| `registry_users` | `list(object)` | no | `[{ login, email }]` |
| `ip_restrictions` | `list(object)` | no | `[{ ip_block, description }]` |

## Outputs

| Name | Description |
|------|-------------|
| `registry_url` | URL / login server of the registry |
| `registry_id` | ID of the registry resource |
| `user_passwords` | Map of usernames → passwords *(sensitive)* |

## Notes

- Azure IP restrictions require `sku = "Premium"` in `container_registry.azure`.
- OVHcloud does not support IAM and local users simultaneously — this wrapper uses local users.
