# Optional OIDC setup against the Kubernetes API:
# ovh_cloud_project_kube_oidc
# https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_kube_oidc

variable "cluster_config" {
  type = object({
    name    = string
    version = string
    plan    = optional(string, "free") # Control-plane plan: "free" or "standard"
    tags    = optional(map(string), {})
  })
  description = "Core Kubernetes cluster settings"
}

# SKU reference: https://www.ovhcloud.com/fr/public-cloud/prices/
variable "node_config" {
  type = object({
    node_pool_name     = optional(string, "defaultpool")
    sku                = string
    node_count         = number
    autoscale_enabled  = bool
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    monthly_billed     = optional(bool, false)
    anti_affinity      = optional(bool, true) # Spread nodes across availability zones
    availability_zones = optional(list(string), [])
    # Attach a public floating IP to each node. Gives nodes public egress WITHOUT
    # a gateway/router — useful in regions where the OVH gateway isn't available
    # (e.g. 3-AZ regions). Works alongside a private network (both interfaces).
    attach_floating_ips = optional(bool, false)
    labels              = optional(map(string), {})
    taints              = optional(list(any), [])
  })
  description = "Default node pool sizing and scaling settings"
}

variable "cloud_settings" {
  type = object({
    ovh_project_id     = string
    ovh_region         = string
    private_network_id = optional(string)
    # Required by OVH when private_network_id is set: OpenStack subnet UUID the
    # nodes are placed in. Load balancers subnet is optional (defaults to nodes).
    nodes_subnet_id          = optional(string)
    load_balancers_subnet_id = optional(string)
    # Node egress on a private network (only applied when private_network_id is set):
    #   false + "" (default) -> egress via OVH's public network (nodes get internet directly)
    #   true  + gateway IP   -> all egress routed through your own gateway on the private net
    private_network_routing_as_default = optional(bool, false)
    default_vrack_gateway              = optional(string, "")
    ip_restrictions                    = optional(list(string), [])
  })
  description = "OVHcloud infrastructure and network specific settings"
}
