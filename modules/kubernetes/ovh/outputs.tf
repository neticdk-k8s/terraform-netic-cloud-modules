output "cluster_id" {
  value       = ovh_cloud_project_kube.kube_cluster.id
  description = "The unique ID of the OVHcloud Kubernetes cluster"
}

output "cluster_endpoint" {
  value       = ovh_cloud_project_kube.kube_cluster.kubeconfig_attributes[0].host
  description = "The Kubernetes API server URL endpoint"
}

output "kubeconfig" {
  value       = ovh_cloud_project_kube.kube_cluster.kubeconfig
  sensitive   = true
  description = "The raw kubeconfig configuration file"
}

output "node_pool_ids" {
  value       = { for k, v in ovh_cloud_project_kube_nodepool.node_pool : k => v.id }
  description = "Map of node pool name to its ID (one pool per availability zone in 3-AZ regions)"
}