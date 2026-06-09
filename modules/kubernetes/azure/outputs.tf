output "cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "The unique resource ID of the AKS cluster"
}

output "cluster_endpoint" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  description = "The Kubernetes API server URL endpoint"
}

output "kubeconfig" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "The raw kubeconfig configuration file"
}

output "cluster_identity_id" {
  description = "The Principal ID of the SystemAssigned Managed Identity created by AKS"
  value       = try(azurerm_kubernetes_cluster.aks.identity[0].principal_id, null)
}
