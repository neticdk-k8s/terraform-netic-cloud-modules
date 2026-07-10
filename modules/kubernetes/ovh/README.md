# Kubernetes — OVHcloud

Provisions an OVHcloud Managed Kubernetes cluster with one or more node pools and optional Kube API IP restrictions.

## Resources created

| Resource | Description |
|----------|-------------|
| `ovh_cloud_project_kube` | Managed Kubernetes cluster |
| `ovh_cloud_project_kube_nodepool` | Node pool(s) with autoscaling and optional labels/taints |
| `ovh_cloud_project_kube_iprestrictions` | Kube API IP allowlist (only created when `ip_restrictions` is non-empty) |

## Usage

```hcl
module "kubernetes" {
  source = "./modules/kubernetes/ovh"

  ovh_project_id = var.ovh_project_id
  ovh_region     = "GRA11"

  kube_cluster = {
    name            = "my-cluster"
    version         = "1.30"
    ip_restrictions = ["203.0.113.0/24"]
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

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `ovh_project_id` | `string` | OVH Public Cloud project ID |
| `ovh_region` | `string` | OVH region (e.g. `"GRA11"`) |
| `private_network_id` | `string` | OpenStack network UUID for the nodes (optional) |
| `nodes_subnet_id` | `string` | OpenStack subnet UUID for the nodes — required by OVH when `private_network_id` is set |
| `load_balancers_subnet_id` | `string` | OpenStack subnet UUID for load balancers (optional; default = nodes subnet) |
| `kube_cluster` | `object` | Cluster configuration (see below) |
| `kube_node_pools` | `map(object)` | Node pools to create (default: `{}`) |

### `kube_cluster`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Cluster name |
| `version` | `string` | — | Kubernetes version (e.g. `"1.30"`) |
| `plan` | `string` | `"free"` | Control-plane plan — `"free"` or `"standard"` (SLA + high-availability control plane) |
| `ip_restrictions` | `list(string)` | `[]` | CIDRs allowed to reach the Kube API |

### `kube_node_pools` map entry

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `size` | `string` | — | OVH flavor name (e.g. `"b3-8"`) |
| `nodes_count` | `number` | — | Initial node count |
| `nodes_min` | `number` | — | Autoscaling lower bound |
| `nodes_max` | `number` | — | Autoscaling upper bound |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | Node taints — `{ key, value, effect }` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the cluster |
| `cluster_name` | Name of the cluster |
| `node_pool_ids` | Map of pool names → IDs |
| `kubeconfig` | Raw kubeconfig string *(sensitive)* |

## Provider

```hcl
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
```
