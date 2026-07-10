output "node_pool_ids" {
  value       = { for k, v in ovh_cloud_project_kube_nodepool.pool : k => v.id }
  description = "Map of node pool name to its ID (one pool per availability zone in 3-AZ regions)"
}
