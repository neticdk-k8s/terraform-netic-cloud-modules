variable "cluster_config" {
  type = object({
    cluster_name = string
    k8s_version  = optional(string, "1.34") # Kubernetes major.minor version (e.g., "1.34")
    tags         = optional(map(string), {}) # Shared infrastructure resource tags
  })
  description = "General cluster metadata and tagging"
}

variable "node_config" {
  type = object({
    node_size          = string                     # T-shirt size ("small", "medium", "large") or direct VM SKU
    node_count         = number                     # Desired base/initial node count
    autoscale_enabled  = bool                       # Shared autoscale switch
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    availability_zones = optional(list(string), []) # Shared availability zones list
    k8s_version        = optional(string, null)      # Node pool version — Azure only; null = same as cluster
    monthly_billed     = optional(bool, false)      # OVH: bill nodes monthly instead of hourly
    anti_affinity      = optional(bool, true)       # OVH: spread nodes across availability zones

    labels = optional(map(string), {})              # Kubernetes node labels
    taints = optional(list(object({                 # Kubernetes node taints
      key    = string
      value  = string
      effect = string
    })), [])
  })
  description = "Unified sizing, scaling, labeling, and taint configurations for the default node pool"
}

variable "cloud_settings" {
  type = object({
    cloud_provider     = string # "azure" or "ovh"
    region             = string # Maps to 'location' in Azure / 'region' in OVH
    project_identifier = string # Maps to 'resource_group' in Azure / 'ovh_project_id' in OVH

    # Optional networking and provider-specific configurations
    network_id       = optional(string, null) # vnet_subnet_id (Azure) / private_network_id (OVH)
    ip_restrictions  = optional(list(string), [])
    azure_dns_prefix = optional(string, null)

    # Azure CNI network ranges — only relevant when cloud_provider = "azure"
    service_cidr   = optional(string, null) # default: 172.16.0.0/16
    dns_service_ip = optional(string, null) # default: 172.16.0.10
  })
  description = "Cloud provider landing zone and networking settings"

  validation {
    condition     = contains(["azure", "ovh"], var.cloud_settings.cloud_provider)
    error_message = "cloud_settings.cloud_provider must be 'azure' or 'ovh'."
  }
}