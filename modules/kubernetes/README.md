# Kubernetes Module

Provisions a managed Kubernetes cluster on either **OVHcloud** (Managed Kubernetes) or **Azure** (AKS) through a single unified interface.

## Directory structure

```
modules/kubernetes/
  wrapper/   — entry point, selects the right cloud provider
  ovh/       — OVHcloud Managed Kubernetes implementation
  azure/     — Azure AKS implementation
```

Call `wrapper/` from your root module. You should never need to call `ovh/` or `azure/` directly.

---

## Usage

### OVHcloud

```hcl
module "kubernetes" {
  source         = "./modules/kubernetes/wrapper"
  cloud_provider = "ovh"

  kube_cluster = {
    name            = "my-cluster"
    version         = "1.30"
    ip_restrictions = ["203.0.113.0/24"]   # optional — restricts Kube API access
  }

  ovh_config = {
    project_id = var.ovh_project_id
    region     = "GRA11"
  }

  kube_node_pools = {
    default = {
      size        = "b3-8"
      nodes_count = 2
      nodes_min   = 1
      nodes_max   = 5
    }
    workers = {
      size        = "b3-32"
      nodes_count = 1
      nodes_min   = 0
      nodes_max   = 10
      labels      = { role = "workers" }
      taints      = [{ key = "dedicated", value = "workers", effect = "NoSchedule" }]
    }
  }
}
```

### Azure (AKS)

```hcl
module "kubernetes" {
  source         = "./modules/kubernetes/wrapper"
  cloud_provider = "azure"

  kube_cluster = {
    name            = "my-cluster"
    version         = "1.30"
    ip_restrictions = ["203.0.113.0/24"]   # optional — restricts Kube API access
  }

  azure_config = {
    location               = "westeurope"
    resource_group         = "my-resource-group"
    default_node_pool_name = "system"      # must match a key in kube_node_pools
    dns_prefix             = "my-cluster"  # optional, defaults to cluster name
  }

  kube_node_pools = {
    system = {                             # this key must match default_node_pool_name
      size        = "Standard_D2s_v3"
      nodes_count = 2
      nodes_min   = 1
      nodes_max   = 5
    }
    workers = {
      size        = "Standard_D8s_v3"
      nodes_count = 1
      nodes_min   = 0
      nodes_max   = 10
      labels      = { role = "workers" }
      taints      = [{ key = "dedicated", value = "workers", effect = "NoSchedule" }]
    }
  }
}
```

---

## Inputs

### Common

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `cloud_provider` | `string` | yes | `"ovh"` or `"azure"` |
| `kube_cluster` | `object` | yes | Common cluster config (see below) |
| `kube_node_pools` | `map(object)` | no | Node pools to create (default: `{}`) |

#### `kube_cluster` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Cluster name |
| `version` | `string` | — | Kubernetes version (e.g. `"1.30"`) |
| `ip_restrictions` | `list(string)` | `[]` | CIDR ranges allowed to reach the Kube API |

#### `kube_node_pools` map entry

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `size` | `string` | — | OVH flavor (e.g. `"b3-8"`) or Azure VM size (e.g. `"Standard_D2s_v3"`) |
| `nodes_count` | `number` | — | Initial node count |
| `nodes_min` | `number` | — | Minimum nodes (autoscaling lower bound) |
| `nodes_max` | `number` | — | Maximum nodes (autoscaling upper bound) |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | Node taints — `{ key, value, effect }` |

### OVH-specific (`ovh_config`)

| Field | Type | Description |
|-------|------|-------------|
| `project_id` | `string` | OVH Public Cloud project ID |
| `region` | `string` | OVH region (e.g. `"GRA11"`) |

### Azure-specific (`azure_config`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `location` | `string` | — | Azure region (e.g. `"westeurope"`) |
| `resource_group` | `string` | — | Name of an existing resource group |
| `default_node_pool_name` | `string` | `"system"` | Key in `kube_node_pools` to use as the AKS system pool |
| `dns_prefix` | `string` | cluster name | DNS prefix for the cluster FQDN |

---

## Outputs

All outputs are identical regardless of cloud provider.

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the created cluster |
| `cluster_name` | Name of the cluster |
| `node_pool_ids` | Map of node pool names → IDs |
| `kubeconfig` | Raw kubeconfig string *(sensitive)* |

### Using the kubeconfig

```hcl
resource "local_file" "kubeconfig" {
  content         = module.kubernetes.kubeconfig
  filename        = "${path.module}/kubeconfig.yaml"
  file_permission = "0600"
}
```

---

## Provider configuration

Configure only the provider you intend to use. The wrapper declares both so Terraform knows their schemas, but only the active provider makes API calls.

### OVHcloud

```hcl
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3"
  tenant_id   = var.ovh_project_id
  user_name   = var.openstack_user
  password    = var.openstack_password
  region      = "GRA11"
}
```

### Azure

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
```

---

## Notes

- **Azure default node pool** — AKS embeds one node pool directly in the cluster resource. The pool whose key matches `azure_config.default_node_pool_name` becomes this system pool. It cannot be deleted independently; to remove it, destroy the entire cluster.
- **AKS node pool name length** — Azure enforces a maximum of 12 lowercase alphanumeric characters per node pool name.
- **Taints format** — Pass taints as structured objects `{ key, value, effect }`. The Azure module converts them to AKS format (`"key=value:Effect"`) automatically.
- **Autoscaling** — Both providers configure autoscaling by default. Set `nodes_min = nodes_max = nodes_count` for a fixed-size pool.
