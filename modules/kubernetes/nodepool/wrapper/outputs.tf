output "node_pool_ids" {
  value = var.nodepool.ovh != null ? one(module.ovh[*].node_pool_ids) : {
    (var.nodepool.name) = one(module.azure[*].node_pool_id)
  }
  description = "Map of node pool name to ID (OVH: one entry per zone; Azure: single entry)"
}
