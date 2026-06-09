output "cluster_endpoint" {
  description = "The API server endpoint for the Kubernetes cluster"
  value       = one(concat(module.azure_k8s_cluster[*].cluster_endpoint, module.ovh_k8s_cluster[*].cluster_endpoint))
}

output "cluster_id" {
  description = "The unique resource ID of the Kubernetes cluster"
  value       = one(concat(module.azure_k8s_cluster[*].cluster_id, module.ovh_k8s_cluster[*].cluster_id))
}

output "kubeconfig" {
  value = one(concat(
    module.azure_k8s_cluster[*].kubeconfig,
    module.ovh_k8s_cluster[*].kubeconfig
  ))
  sensitive = true
}

output "cluster_identity_id" {
  description = "The Principal ID of the cluster identity (Azure specific)"
  value       = one(module.azure_k8s_cluster[*].cluster_identity_id)
}