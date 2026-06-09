# Optional OIDC setup against the Kubernetes API:
# ovh_cloud_project_kube_oidc
# https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_kube_oidc

variable "cluster_config" {
  type = object({
    name    = string
    version = string
    tags        = optional(map(string), {})
  })
  description = "Core Kubernetes cluster settings"
}

# SKU reference: https://www.ovhcloud.com/fr/public-cloud/prices/
variable "node_config" {
  type = object({
    sku                = string
    node_count         = number
    autoscale_enabled  = bool
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    monthly_billed     = optional(bool, false)
    anti_affinity      = optional(bool, true)       # Spread nodes across availability zones
    availability_zones = optional(list(string), [])
    labels             = optional(map(string), {})
    taints             = optional(list(any), [])
  })
  description = "Default node pool sizing and scaling settings"
}

variable "cloud_settings" {
  type = object({
    ovh_project_id     = string
    ovh_region         = string
    private_network_id = optional(string)
    ip_restrictions    = optional(list(string), [])
  })
  description = "OVHcloud infrastructure and network specific settings"
}
