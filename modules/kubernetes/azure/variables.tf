variable "cluster_config" {
  type = object({
    name    = string
    version = string
    tags    = optional(map(string), {})
  })
  description = "Core Kubernetes cluster settings"
}

variable "node_config" {
  type = object({
    sku                = string
    node_count         = number
    autoscale_enabled  = bool
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    availability_zones = optional(list(string), [])
    k8s_version        = optional(string, null) # orchestrator_version on the node pool; null = inherits from cluster
    labels             = optional(map(string), {})
    taints             = optional(list(any), [])
  })
  description = "Default node pool sizing and scaling settings"
}

variable "cloud_settings" {
  type = object({
    resource_group  = string
    location        = string
    dns_prefix      = string
    vnet_subnet_id  = optional(string)
    ip_restrictions = optional(list(string), [])
    service_cidr    = optional(string, "172.16.0.0/16")
    dns_service_ip  = optional(string, "172.16.0.10")
  })
  description = "Azure infrastructure and network specific settings"
}
