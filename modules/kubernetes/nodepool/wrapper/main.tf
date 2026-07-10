module "ovh" {
  count  = var.nodepool.ovh != null ? 1 : 0
  source = "../ovh"

  nodepool = {
    service_name        = var.nodepool.ovh.service_name
    kube_id             = var.nodepool.ovh.kube_id
    name                = var.nodepool.name
    flavor              = local.resolved_node_sku
    desired_nodes       = var.nodepool.node_count
    autoscale           = var.nodepool.autoscale_enabled
    min_nodes           = var.nodepool.min_count
    max_nodes           = var.nodepool.max_count
    availability_zones  = var.nodepool.availability_zones
    monthly_billed      = var.nodepool.ovh.monthly_billed
    anti_affinity       = var.nodepool.ovh.anti_affinity
    attach_floating_ips = var.nodepool.ovh.attach_floating_ips
    labels              = var.nodepool.labels
    taints              = var.nodepool.taints
  }
}

module "azure" {
  count  = var.nodepool.azure != null ? 1 : 0
  source = "../azure"

  nodepool = {
    cluster_id         = var.nodepool.azure.cluster_id
    name               = var.nodepool.name
    vm_size            = local.resolved_node_sku
    node_count         = var.nodepool.node_count
    autoscale          = var.nodepool.autoscale_enabled
    min_count          = var.nodepool.min_count
    max_count          = var.nodepool.max_count
    availability_zones = var.nodepool.availability_zones
    vnet_subnet_id     = var.nodepool.azure.vnet_subnet_id
    labels             = var.nodepool.labels
    taints             = local.azure_taints
    tags               = var.nodepool.azure.tags
  }
}
