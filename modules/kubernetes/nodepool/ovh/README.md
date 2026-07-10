# Node Pool — OVH

Opretter en eller flere `ovh_cloud_project_kube_nodepool` på et eksisterende
OVH Managed Kubernetes-cluster.

I et **3AZ-region** ligger hver node pool i én zone, så angiver du flere
`availability_zones`, oprettes **én pool pr. zone** (navnet får zone-koden som
suffix, fx `mempool-a`). `desired/min/max` gælder pr. pool. I single-AZ-regioner
lader du `availability_zones` være tom → én upinned pool.

Foretræk [`wrapper`](../wrapper) for t-shirt-størrelser og cloud-agnostisk API.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `nodepool.service_name` | `string` | — | OVH public cloud project ID |
| `nodepool.kube_id` | `string` | — | ID på clusteret |
| `nodepool.name` | `string` | — | Pool-navn (suffixes pr. zone ved fan-out) |
| `nodepool.flavor` | `string` | — | OVH flavor, fx `"b3-8"` |
| `nodepool.desired_nodes` | `number` | — | Ønskede noder pr. pool |
| `nodepool.autoscale` | `bool` | `false` | Autoscaling |
| `nodepool.min_nodes` / `max_nodes` | `number` | `null` | Autoscale-grænser |
| `nodepool.availability_zones` | `list(string)` | `[]` | Én pool pr. zone (3AZ) |
| `nodepool.monthly_billed` | `bool` | `false` | Månedlig fakturering |
| `nodepool.anti_affinity` | `bool` | `false` | Anti-affinity i pool'en |
| `nodepool.labels` | `map(string)` | `{}` | Node labels |
| `nodepool.taints` | `list(any)` | `[]` | Node taints (`{ key, value, effect }`) |

## Outputs

| Name | Description |
|------|-------------|
| `node_pool_ids` | Map af pool-navn → ID |
