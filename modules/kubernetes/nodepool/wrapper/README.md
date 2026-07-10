# Node Pool — Wrapper

Tilføjer en **ekstra node pool** til et eksisterende Kubernetes-cluster på enten
**Azure** eller **OVH**. Sæt præcis ét af `nodepool.azure` / `nodepool.ovh`.

Fælles sizing/scaling ligger i toppen (samme t-shirt-størrelser som
`kubernetes/wrapper`); kun cluster-ID og cloud-specifikt ligger under `azure`/`ovh`.

> **OVH 3AZ:** angiver du flere `availability_zones`, opretter OVH-delen **én pool
> pr. zone** (`node_count` gælder pr. pool). Azure spreder derimod én pool over de
> angivne zoner.

## Usage

### OVH — tilføj en memory-pool spredt over 3 AZ'er

```hcl
module "extra_pool" {
  source = "./modules/kubernetes/nodepool/wrapper"

  nodepool = {
    name               = "mempool"
    node_size          = "memory-large"
    node_count         = 1
    availability_zones = ["eu-south-mil-a", "eu-south-mil-b", "eu-south-mil-c"]

    ovh = {
      service_name = var.ovh_project_id
      kube_id      = module.utility_cluster.cluster_id
    }
  }
}
```

### Azure — tilføj en spot/GPU-pool

```hcl
module "extra_pool" {
  source = "./modules/kubernetes/nodepool/wrapper"

  nodepool = {
    name       = "gpupool"
    node_size  = "large"
    node_count = 2
    taints     = [{ key = "dedicated", value = "gpu", effect = "NoSchedule" }]

    azure = {
      cluster_id     = module.cluster.cluster_id
      vnet_subnet_id = module.network.subnet_ids["aks"]
    }
  }
}
```

## Inputs

Sæt præcis ét af `nodepool.azure` / `nodepool.ovh`.

Fælles:

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Pool-navn (OVH suffixes med zone-kode ved fan-out) |
| `node_size` | `string` | — | T-shirt-størrelse eller rå SKU/flavor |
| `node_count` | `number` | — | Ønskede noder (pr. pool/zone på OVH 3AZ) |
| `autoscale_enabled` | `bool` | `false` | Slå autoscaling til |
| `min_count` / `max_count` | `number` | `null` | Autoscale-grænser |
| `availability_zones` | `list(string)` | `[]` | Azure: zoner på pool'en. OVH 3AZ: én pool pr. zone |
| `labels` | `map(string)` | `{}` | Node labels |
| `taints` | `list(object)` | `[]` | `{ key, value, effect }` (mappes til Azure-format automatisk) |

### `nodepool.azure`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_id` | `string` | — | ID på AKS-clusteret |
| `vnet_subnet_id` | `string` | `null` | Subnet til noderne |
| `tags` | `map(string)` | `{}` | Tags |

### `nodepool.ovh`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `service_name` | `string` | — | OVH public cloud project ID |
| `kube_id` | `string` | — | ID på OVH-clusteret |
| `monthly_billed` | `bool` | `false` | Månedlig fakturering af noderne |
| `anti_affinity` | `bool` | `false` | Anti-affinity inden for pool'en |

## Outputs

| Name | Description |
|------|-------------|
| `node_pool_ids` | Map af pool-navn → ID (OVH: én pr. zone; Azure: én) |
