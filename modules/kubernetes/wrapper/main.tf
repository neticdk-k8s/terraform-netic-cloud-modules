module "azure_k8s_cluster" {
  source = "../azure"
  count  = var.cloud_settings.azure != null ? 1 : 0

  cluster_config = {
    name    = var.cluster_config.cluster_name
    version = var.cluster_config.k8s_version
    plan    = title(lower(var.cluster_config.plan)) # "free"/"standard" -> "Free"/"Standard"
    tags    = var.cluster_config.tags
  }

  node_config = {
    node_pool_name     = var.node_config.node_pool_name
    sku                = local.resolved_node_sku
    node_count         = var.node_config.node_count
    autoscale_enabled  = var.node_config.autoscale_enabled
    min_count          = var.node_config.min_count
    max_count          = var.node_config.max_count
    availability_zones = var.node_config.availability_zones
    k8s_version        = coalesce(var.node_config.k8s_version, var.cluster_config.k8s_version)
    labels             = var.node_config.labels
    taints             = var.node_config.taints
  }

  cloud_settings = {
    resource_group  = var.cloud_settings.azure.resource_group
    location        = var.cloud_settings.region
    dns_prefix      = coalesce(var.cloud_settings.azure.dns_prefix, var.cluster_config.cluster_name)
    vnet_subnet_id  = var.cloud_settings.azure.subnet_id
    ip_restrictions = var.cloud_settings.ip_restrictions
    service_cidr    = var.cloud_settings.azure.service_cidr
    dns_service_ip  = var.cloud_settings.azure.dns_service_ip
  }
}

module "ovh_k8s_cluster" {
  source = "../ovh"
  count  = var.cloud_settings.ovh != null ? 1 : 0

  cluster_config = {
    name    = var.cluster_config.cluster_name
    version = var.cluster_config.k8s_version
    plan    = lower(var.cluster_config.plan) # OVH expects lowercase "free"/"standard"
    tags    = var.cluster_config.tags
  }

  node_config = {
    node_pool_name      = var.node_config.node_pool_name
    sku                 = local.resolved_node_sku
    node_count          = var.node_config.node_count
    autoscale_enabled   = var.node_config.autoscale_enabled
    min_count           = var.node_config.min_count
    max_count           = var.node_config.max_count
    availability_zones  = var.node_config.availability_zones
    monthly_billed      = var.node_config.monthly_billed
    anti_affinity       = var.node_config.anti_affinity
    attach_floating_ips = var.node_config.attach_floating_ips
    labels              = var.node_config.labels
    taints              = var.node_config.taints
  }

  cloud_settings = {
    ovh_project_id           = var.cloud_settings.ovh.project_id
    ovh_region               = var.cloud_settings.region
    private_network_id       = var.cloud_settings.ovh.private_network_id
    nodes_subnet_id          = var.cloud_settings.ovh.nodes_subnet_id
    load_balancers_subnet_id = var.cloud_settings.ovh.load_balancers_subnet_id

    private_network_routing_as_default = var.cloud_settings.ovh.private_network_routing_as_default
    default_vrack_gateway              = var.cloud_settings.ovh.default_vrack_gateway

    ip_restrictions = var.cloud_settings.ip_restrictions
  }
}
