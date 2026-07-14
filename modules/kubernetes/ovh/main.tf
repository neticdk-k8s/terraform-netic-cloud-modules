# Create an OVHcloud Managed Kubernetes cluster
resource "ovh_cloud_project_kube" "kube_cluster" {
  service_name       = var.cloud_settings.ovh_project_id
  name               = var.cluster_config.name
  region             = var.cloud_settings.ovh_region
  version            = var.cluster_config.version
  plan               = var.cluster_config.plan
  private_network_id = var.cloud_settings.private_network_id

  # OVH requires nodes_subnet_id when a private network is attached.
  nodes_subnet_id          = var.cloud_settings.nodes_subnet_id
  load_balancers_subnet_id = var.cloud_settings.load_balancers_subnet_id

  # Controls node egress on a private network. Without this block OVH's default
  # is undefined and nodes may end up with no route to the internet.
  #   routing_as_default = false + gateway "" -> egress via OVH's public network
  #   routing_as_default = true  + gateway IP -> egress via your own gateway (vRack)
  dynamic "private_network_configuration" {
    for_each = var.cloud_settings.private_network_id != null ? [1] : []
    content {
      private_network_routing_as_default = var.cloud_settings.private_network_routing_as_default
      default_vrack_gateway              = var.cloud_settings.default_vrack_gateway
    }
  }

  #  update_policy = "MINIMAL_DOWNTIME" # Options: ALWAYS_UPDATE, MINIMAL_DOWNTIME, NEVER_UPDATE

  timeouts {
    create = "45m"
    update = "45m"
    delete = "10m"
  }
}

locals {
  # In a 3-AZ region each node pool lives in a SINGLE zone, so fan out one pool
  # per availability zone (name suffixed with the zone's short code, e.g.
  # "defaultpool-a"). With no zones given, create a single unpinned pool
  # (single-AZ region behaviour). node_count / min / max apply PER pool (per zone).
  node_pools = length(var.node_config.availability_zones) > 0 ? {
    for az in var.node_config.availability_zones :
    "${var.node_config.node_pool_name}-${element(split("-", az), length(split("-", az)) - 1)}" => az
  } : { (var.node_config.node_pool_name) = null }
}

# Create Managed Node Pool(s) — one per availability zone in 3-AZ regions.
resource "ovh_cloud_project_kube_nodepool" "node_pool" {
  for_each = local.node_pools

  service_name = var.cloud_settings.ovh_project_id
  kube_id      = ovh_cloud_project_kube.kube_cluster.id

  name          = each.key
  flavor_name   = var.node_config.sku
  desired_nodes = var.node_config.node_count

  # Autoscale configuration mapping
  autoscale = var.node_config.autoscale_enabled
  min_nodes = var.node_config.autoscale_enabled ? var.node_config.min_count : var.node_config.node_count
  max_nodes = var.node_config.autoscale_enabled ? var.node_config.max_count : var.node_config.node_count

  # One zone per pool; null (unpinned) when the region isn't multi-AZ.
  availability_zones = each.value == null ? null : [each.value]

  monthly_billed = var.node_config.monthly_billed
  anti_affinity  = var.node_config.anti_affinity

  # Public floating IP per node (public egress without a gateway/router).
  # Blokken udsendes KUN når den er slået til: OVH afviser den (422) på clustere der
  # ikke understøtter floating IPs — selv med enabled = false. Den skal være unset.
  dynamic "attach_floating_ips" {
    for_each = var.node_config.attach_floating_ips ? [1] : []
    content {
      enabled = true
    }
  }

  template {
    metadata {
      # Restored metadata tracking and deletion handling blocks
      annotations = {
        "managed-by" = "terraform"
      }
      finalizers = []

      labels = merge(var.cluster_config.tags, var.node_config.labels)
    }

    spec {
      unschedulable = false
      taints        = var.node_config.taints
    }
  }
  timeouts {
    create = "45m"
    update = "45m"
    delete = "30m" # OVH node pool deletion is often slow; 10m frequently times out mid-delete
  }
}

# Kube-API IP Access restrictions
resource "ovh_cloud_project_kube_iprestrictions" "restrictions" {
  count        = length(var.cloud_settings.ip_restrictions) > 0 ? 1 : 0
  service_name = var.cloud_settings.ovh_project_id
  kube_id      = ovh_cloud_project_kube.kube_cluster.id
  ips          = var.cloud_settings.ip_restrictions

  # Must be destroyed before the node pool — OVH API rejects ipRestriction updates
  # while a node pool is in DELETING status.
  depends_on = [ovh_cloud_project_kube_nodepool.node_pool]
}
