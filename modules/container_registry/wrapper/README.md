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

## Using it in context — pulling images

`registry_url` + `user_passwords` are what a client needs to authenticate. Two
common consumers:

### Kubernetes — imagePullSecret

Turn the credentials into a `kubernetes.io/dockerconfigjson` secret that pods
reference via `imagePullSecrets`:

```hcl
module "registry" {
  source             = "./modules/container_registry/wrapper"
  container_registry = { deploy = true, name = "myreg", ovh = { project_id = var.ovh_project_id, region = "GRA" } }
  registry_users     = [{ login = "ci", email = "ci@example.com" }]
}

resource "kubernetes_secret" "regcred" {
  metadata { name = "regcred" }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (module.registry.registry_url) = {
          username = "ci"
          password = module.registry.user_passwords["ci"]
          auth     = base64encode("ci:${module.registry.user_passwords["ci"]}")
        }
      }
    })
  }
}
# In a pod/deployment spec: imagePullSecrets: [{ name: regcred }]
```

### A VM / CI runner — docker login via cloud-init

```hcl
module "vm" {
  source = "./modules/vm/wrapper"
  vm = {
    name           = "runner"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id
    user_data      = <<-EOT
      #cloud-config
      runcmd:
        - echo '${module.registry.user_passwords["ci"]}' | docker login ${module.registry.registry_url} -u ci --password-stdin
    EOT
    ovh = { project_id = var.ovh_project_id, image_name = "Ubuntu 24.04", network_names = [module.network.network_name] }
  }
}
```

> `user_passwords` is `sensitive` and stored in Terraform state. Index it by the
> `login` you defined in `registry_users`. For production, source the password
> from a secrets manager rather than embedding it in `user_data`.

## Notes

- Azure IP restrictions require `sku = "Premium"` in `container_registry.azure`.
- OVHcloud does not support IAM and local users simultaneously — this wrapper uses local users.
