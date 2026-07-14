locals {
  # In a 3-AZ region each node pool lives in a SINGLE zone, so fan out one pool
  # per availability zone (name suffixed with the zone short code, e.g. "-a").
  # With no zones given, create a single unpinned pool (single-AZ behaviour).
  node_pools = length(var.nodepool.availability_zones) > 0 ? {
    for az in var.nodepool.availability_zones :
    "${var.nodepool.name}-${element(split("-", az), length(split("-", az)) - 1)}" => az
  } : { (var.nodepool.name) = null }
}

resource "ovh_cloud_project_kube_nodepool" "pool" {
  for_each = local.node_pools

  service_name = var.nodepool.service_name
  kube_id      = var.nodepool.kube_id

  name          = each.key
  flavor_name   = var.nodepool.flavor
  desired_nodes = var.nodepool.desired_nodes

  autoscale = var.nodepool.autoscale
  min_nodes = var.nodepool.autoscale ? var.nodepool.min_nodes : var.nodepool.desired_nodes
  max_nodes = var.nodepool.autoscale ? var.nodepool.max_nodes : var.nodepool.desired_nodes

  availability_zones = each.value == null ? null : [each.value]

  monthly_billed = var.nodepool.monthly_billed
  anti_affinity  = var.nodepool.anti_affinity

  # Blokken udsendes KUN når den er slået til: OVH afviser den (422) på clustere der
  # ikke understøtter floating IPs — selv med enabled = false. Den skal være unset.
  dynamic "attach_floating_ips" {
    for_each = var.nodepool.attach_floating_ips ? [1] : []
    content {
      enabled = true
    }
  }

  template {
    metadata {
      annotations = {
        "managed-by" = "terraform"
      }
      finalizers = []
      labels     = var.nodepool.labels
    }
    spec {
      unschedulable = false
      taints        = var.nodepool.taints
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "30m" # OVH node pool deletion is often slow; 10m frequently times out mid-delete
  }
}
