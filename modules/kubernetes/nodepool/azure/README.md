# Node Pool — Azure

Opretter en `azurerm_kubernetes_cluster_node_pool` (user pool) på et eksisterende
AKS-cluster. Azure spreder én pool over de angivne `availability_zones` — der er
ingen fan-out (modsat OVH 3AZ).

Foretræk [`wrapper`](../wrapper) for t-shirt-størrelser og cloud-agnostisk API.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `nodepool.cluster_id` | `string` | — | ID på AKS-clusteret |
| `nodepool.name` | `string` | — | Pool-navn |
| `nodepool.vm_size` | `string` | — | Azure VM SKU, fx `"Standard_D4ads_v6"` |
| `nodepool.node_count` | `number` | — | Antal noder |
| `nodepool.autoscale` | `bool` | `false` | Autoscaling |
| `nodepool.min_count` / `max_count` | `number` | `null` | Autoscale-grænser |
| `nodepool.availability_zones` | `list(string)` | `[]` | Zoner pool'en spredes over |
| `nodepool.vnet_subnet_id` | `string` | `null` | Subnet til noderne |
| `nodepool.labels` | `map(string)` | `{}` | Node labels |
| `nodepool.taints` | `list(string)` | `[]` | Taints, fx `"dedicated=gpu:NoSchedule"` |
| `nodepool.tags` | `map(string)` | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `node_pool_id` | Resource ID på node pool'en |
