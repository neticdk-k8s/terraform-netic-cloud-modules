variable "cluster_config" {
  type = object({
    cluster_name = string
    k8s_version  = optional(string, "1.34")  # Kubernetes major.minor version (e.g., "1.34")
    plan         = optional(string, "free")  # Control-plane tier: "free" or "standard" (Azure Free/Standard SKU tier, OVH free/standard plan)
    tags         = optional(map(string), {}) # Shared infrastructure resource tags
  })
  description = "General cluster metadata and tagging"

  validation {
    condition     = contains(["free", "standard"], lower(var.cluster_config.plan))
    error_message = "cluster_config.plan must be \"free\" or \"standard\"."
  }
}

variable "node_config" {
  type = object({
    node_pool_name      = optional(string, "defaultpool") # Name of the default node pool
    node_size           = string                          # T-shirt size ("small", "medium", "large") or direct VM SKU
    node_count          = number                          # Desired base/initial node count
    autoscale_enabled   = bool                            # Shared autoscale switch
    min_count           = optional(number, null)
    max_count           = optional(number, null)
    availability_zones  = optional(list(string), []) # Azure: zones on the single pool. OVH 3-AZ: one node pool created per zone (node_count applies per pool).
    k8s_version         = optional(string, null)     # Node pool version — Azure only; null = same as cluster
    monthly_billed      = optional(bool, false)      # OVH: bill nodes monthly instead of hourly
    anti_affinity       = optional(bool, true)       # OVH: spread nodes across availability zones
    attach_floating_ips = optional(bool, false)      # OVH: give each node a public floating IP (egress without a gateway/router)

    labels = optional(map(string), {}) # Kubernetes node labels
    taints = optional(list(object({    # Kubernetes node taints
      key    = string
      value  = string
      effect = string
    })), [])
  })
  description = "Unified sizing, scaling, labeling, and taint configurations for the default node pool"
}

variable "cloud_settings" {
  type = object({
    region          = string                     # Azure location / OVH region
    ip_restrictions = optional(list(string), []) # CIDR ranges allowed to reach the Kubernetes API

    azure = optional(object({
      resource_group = string
      subnet_id      = optional(string, null) # VNet subnet for the node pool
      dns_prefix     = optional(string, null) # null = cluster name
      service_cidr   = optional(string, "172.16.0.0/16")
      dns_service_ip = optional(string, "172.16.0.10")
    }), null)

    ovh = optional(object({
      project_id         = string
      private_network_id = optional(string, null)
      # Required by OVH when private_network_id is set — subnet the nodes go in.
      nodes_subnet_id          = optional(string, null)
      load_balancers_subnet_id = optional(string, null)
      # Node egress: false (default) = via OVH public network; true + gateway IP = via your gateway.
      private_network_routing_as_default = optional(bool, false)
      default_vrack_gateway              = optional(string, "")
    }), null)
  })
  description = "Cloud provider landing zone and networking settings. Set exactly one of cloud_settings.azure or cloud_settings.ovh."

  validation {
    condition     = (var.cloud_settings.azure != null) != (var.cloud_settings.ovh != null)
    error_message = "Exactly one of cloud_settings.azure or cloud_settings.ovh must be set."
  }
}
