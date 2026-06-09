# Kubernetes — Azure (AKS)

Provisions an Azure Kubernetes Service (AKS) cluster with one system node pool and any number of additional user node pools.

## Resources created

| Resource | Description |
|----------|-------------|
| `azurerm_kubernetes_cluster` | AKS cluster with SystemAssigned identity and autoscaling |
| `azurerm_kubernetes_cluster_node_pool` | Additional node pools beyond the system pool |

## Usage

```hcl
module "kubernetes" {
  source = "./modules/kubernetes/azure"

  kube_cluster = {
    name                   = "my-cluster"
    version                = "1.30"
    location               = "westeurope"
    resource_group         = "my-resource-group"
    default_node_pool_name = "system"
    ip_restrictions        = ["203.0.113.0/24"]
  }

  kube_node_pools = {
    system = {
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

## Inputs

### `kube_cluster`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Cluster name |
| `version` | `string` | — | Kubernetes version (e.g. `"1.30"`) |
| `location` | `string` | — | Azure region (e.g. `"westeurope"`) |
| `resource_group` | `string` | — | Name of an existing resource group |
| `default_node_pool_name` | `string` | `"system"` | Key in `kube_node_pools` to use as the AKS system pool |
| `dns_prefix` | `string` | cluster name | DNS prefix for the cluster FQDN |
| `ip_restrictions` | `list(string)` | `[]` | CIDR ranges allowed to reach the Kube API |

### `kube_node_pools` map entry

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `size` | `string` | — | Azure VM size (e.g. `"Standard_D2s_v3"`) |
| `nodes_count` | `number` | — | Initial node count |
| `nodes_min` | `number` | — | Autoscaling lower bound |
| `nodes_max` | `number` | — | Autoscaling upper bound |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | Node taints — `{ key, value, effect }` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the AKS cluster |
| `cluster_name` | Name of the cluster |
| `node_pool_ids` | Map of pool names → IDs (includes the system pool) |
| `kubeconfig` | Raw kubeconfig string *(sensitive)* |

## Provider

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
```

## Notes

- **System pool** — The pool matching `default_node_pool_name` is embedded in the cluster resource. It cannot be deleted independently; removing it requires destroying the entire cluster.
- **Node pool name length** — Azure enforces a maximum of 12 lowercase alphanumeric characters.
- **Taints** — Passed as `{ key, value, effect }` objects and converted to AKS format (`"key=value:Effect"`) automatically.
- **Autoscaling** — Always enabled. Set `nodes_min = nodes_max = nodes_count` for a fixed-size pool.
