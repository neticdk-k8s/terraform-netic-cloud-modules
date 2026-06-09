# Kubernetes — Wrapper

Fælles indgangspunkt til at deploye et managed Kubernetes-cluster på enten **OVHcloud** eller **Azure**. Cloud-valget sker via `cloud_settings.cloud_provider`.

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
    cloud_provider     = "ovh"
    region             = "GRA11"
    project_identifier = var.ovh_project_id
    network_id         = module.network.network_id
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
    cloud_provider     = "azure"
    region             = "westeurope"
    project_identifier = "my-rg"
    network_id         = module.network.subnet_ids["aks"]
  }
}
```

## Inputs

### `cluster_config`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | — | Clusternavn |
| `k8s_version` | `string` | `"1.34"` | Kubernetes major.minor version |
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
| `monthly_billed` | `bool` | `false` | OVH: månedlig fakturering |
| `anti_affinity` | `bool` | `true` | OVH: spred noder på tværs af zoner |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | Kubernetes node taints `{ key, value, effect }` |

### `cloud_settings`

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cloud_provider` | `string` | — | `"azure"` eller `"ovh"` |
| `region` | `string` | — | Azure location eller OVH region |
| `project_identifier` | `string` | — | Azure resource group eller OVH project ID |
| `network_id` | `string` | `null` | Subnet ID (Azure) eller private network ID (OVH) |
| `ip_restrictions` | `list(string)` | `[]` | CIDR-ranges med adgang til Kubernetes API |
| `azure_dns_prefix` | `string` | `null` | DNS-præfix til AKS (kun Azure) |
| `service_cidr` | `string` | `null` | Azure CNI service CIDR (default: `172.16.0.0/16`) |
| `dns_service_ip` | `string` | `null` | Azure CNI DNS service IP (default: `172.16.0.10`) |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID på det oprettede cluster |
| `cluster_endpoint` | Kubernetes API server URL |
| `kubeconfig` | Raw kubeconfig *(sensitive)* |
| `cluster_identity_id` | Managed Identity Principal ID (kun Azure) |
