resource "azurerm_kubernetes_cluster_node_pool" "pool" {
  name                  = var.nodepool.name
  kubernetes_cluster_id = var.nodepool.cluster_id
  vm_size               = var.nodepool.vm_size
  node_count            = var.nodepool.node_count
  vnet_subnet_id        = var.nodepool.vnet_subnet_id

  auto_scaling_enabled = var.nodepool.autoscale
  min_count            = var.nodepool.autoscale ? var.nodepool.min_count : null
  max_count            = var.nodepool.autoscale ? var.nodepool.max_count : null

  zones = length(var.nodepool.availability_zones) > 0 ? var.nodepool.availability_zones : null

  node_labels = var.nodepool.labels
  node_taints = var.nodepool.taints
  tags        = var.nodepool.tags
}
