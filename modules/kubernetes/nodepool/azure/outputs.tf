output "node_pool_id" {
  value       = azurerm_kubernetes_cluster_node_pool.pool.id
  description = "Resource ID of the AKS node pool"
}
