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