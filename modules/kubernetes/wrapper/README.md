# Kubernetes — Wrapper

Fælles indgangspunkt til at deploye et managed Kubernetes-cluster på enten **OVHcloud** eller **Azure**.

Provider vælges ved at sætte præcis ét af `cloud_settings.ovh` eller `cloud_settings.azure`.

## Usage

### OVHcloud

```hcl
module "kubernetes" {
  source = "./modules/kubernetes/wrapper"

  cluster_config = {
    cluster_name = "my-cluster"
    k8s_version  = "1.32"
  }

  node_config = {
    node_size         = "b3-8"
    node_count        = 2
    autoscale_enabled = true
    min_count         = 1
    max_count         = 5
  }

  cloud_settings = {
    region = "GRA11"

    ovh = {
      project_id         = var.ovh_project_id
      private_network_id = module.network.network_id
    }
  }
}

output "kubeconfig" {
  value     = module.kubernetes.kubeconfig
  sensitive = true
}
```

### Azure

```hcl
module "kubernetes" {
  source = "./modules/kubernetes/wrapper"

  cluster_config = {
    cluster_name = "my-cluster"
    k8s_version  = "1.32"
  }

  node_config = {
    node_size         = "Standard_D4s_v3"
    node_count        = 2
    autoscale_enabled = true
    min_count         = 1
    max_count         = 5
  }

  cloud_settings = {
    region = "westeurope"

    azure = {
      resource_group = "my-rg"
      subnet_id      = module.network.subnet_ids["aks"]
    }
  }
}
```

## Inputs

### `cluster_config`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | — | Clusternavn |
| `k8s_version` | `string` | `"1.34"` | Kubernetes major.minor version |
| `plan` | `string` | `"free"` | Control-plane tier — `"free"` eller `"standard"` (Azure: Free/Standard SKU tier, OVH: free/standard plan) |
| `tags` | `map(string)` | `{}` | Tags på ressourcerne |

### `node_config`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `node_size` | `string` | — | VM-størrelse eller T-shirt size (`"small"`, `"medium"`, `"large"`) |
| `node_count` | `number` | — | Ønsket antal noder |
| `autoscale_enabled` | `bool` | — | Aktiver autoskalering |
| `min_count` | `number` | `null` | Minimum antal noder |
| `max_count` | `number` | `null` | Maksimum antal noder |
| `availability_zones` | `list(string)` | `[]` | Availability zones |
| `k8s_version` | `string` | `null` | Nodepool-version (kun Azure); `null` = samme som cluster |
| `monthly_billed` | `bool` | `false` | OVH: månedlig fakturering |
| `anti_affinity` | `bool` | `true` | OVH: spred noder på tværs af zoner |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | Kubernetes node taints `{ key, value, effect }` |

### `cloud_settings`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | — | Azure location eller OVH region |
| `ip_restrictions` | `list(string)` | `[]` | CIDR-ranges med adgang til Kubernetes API |
| `azure` | `object` | `null` | Azure-config — sæt præcis ét af `azure` / `ovh` |
| `azure.resource_group` | `string` | — | Resource group |
| `azure.subnet_id` | `string` | `null` | VNet subnet til nodepoolen |
| `azure.dns_prefix` | `string` | `null` | DNS-præfix til AKS; `null` = clusternavn |
| `azure.service_cidr` | `string` | `"172.16.0.0/16"` | Azure CNI service CIDR |
| `azure.dns_service_ip` | `string` | `"172.16.0.10"` | Azure CNI DNS service IP |
| `ovh` | `object` | `null` | OVH-config |
| `ovh.project_id` | `string` | — | OVH project ID |
| `ovh.private_network_id` | `string` | `null` | Privat netværk (vRack) til noderne |
| `ovh.nodes_subnet_id` | `string` | `null` | OpenStack subnet-UUID til noderne — **kræves af OVH når `private_network_id` er sat** |
| `ovh.load_balancers_subnet_id` | `string` | `null` | OpenStack subnet-UUID til load balancers (default = nodes-subnet) |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID på det oprettede cluster |
| `cluster_endpoint` | Kubernetes API server URL |
| `kubeconfig` | Raw kubeconfig *(sensitive)* |
| `cluster_identity_id` | Managed Identity Principal ID (kun Azure) |
