module "azure_k8s_cluster" {
  source = "../azure"
  count  = var.cloud_settings.cloud_provider == "azure" ? 1 : 0

  cluster_config = {
    name    = var.cluster_config.cluster_name
    version = var.cluster_config.k8s_version
    tags    = var.cluster_config.tags
  }

  node_config = {
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
    resource_group  = var.cloud_settings.project_identifier
    location        = var.cloud_settings.region
    dns_prefix      = coalesce(var.cloud_settings.azure_dns_prefix, var.cluster_config.cluster_name)
    vnet_subnet_id  = var.cloud_settings.network_id
    ip_restrictions = var.cloud_settings.ip_restrictions
    service_cidr    = coalesce(var.cloud_settings.service_cidr, "172.16.0.0/16")
    dns_service_ip  = coalesce(var.cloud_settings.dns_service_ip, "172.16.0.10")
  }
}

module "ovh_k8s_cluster" {
  source = "../ovh"
  count  = var.cloud_settings.cloud_provider == "ovh" ? 1 : 0

  cluster_config = {
    name    = var.cluster_config.cluster_name
    version = var.cluster_config.k8s_version
    tags    = var.cluster_config.tags
  }

  node_config = {
    sku                = local.resolved_node_sku
    node_count         = var.node_config.node_count
    autoscale_enabled  = var.node_config.autoscale_enabled
    min_count          = var.node_config.min_count
    max_count          = var.node_config.max_count
    availability_zones = var.node_config.availability_zones
    monthly_billed     = var.node_config.monthly_billed
    anti_affinity      = var.node_config.anti_affinity
    labels             = var.node_config.labels
    taints             = var.node_config.taints
  }

  cloud_settings = {
    ovh_project_id     = var.cloud_settings.project_identifier
    ovh_region         = var.cloud_settings.region
    private_network_id = var.cloud_settings.network_id
    ip_restrictions    = var.cloud_settings.ip_restrictions
  }
}
