variable "nodepool" {
  type = object({
    name               = string
    node_size          = string # T-shirt size ("small", "memory-large", …) or a raw SKU/flavor
    node_count         = number # Desired nodes (per pool/zone on OVH 3-AZ)
    autoscale_enabled  = optional(bool, false)
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    availability_zones = optional(list(string), []) # Azure: zones on the pool. OVH 3-AZ: one pool per zone.
    labels             = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    azure = optional(object({
      cluster_id     = string
      vnet_subnet_id = optional(string, null)
      tags           = optional(map(string), {})
    }), null)

    ovh = optional(object({
      service_name        = string
      kube_id             = string
      monthly_billed      = optional(bool, false)
      anti_affinity       = optional(bool, false)
      attach_floating_ips = optional(bool, false) # public floating IP per node (egress without a gateway/router)
    }), null)
  })
  description = <<-EOT
    Additional Kubernetes node pool for an existing cluster. Set exactly one of
    nodepool.azure or nodepool.ovh. Common sizing/scaling settings live at the top
    level; only cluster identifiers and cloud-specifics sit under azure/ovh.
  EOT

  validation {
    condition     = (var.nodepool.azure != null) != (var.nodepool.ovh != null)
    error_message = "Exactly one of nodepool.azure or nodepool.ovh must be set."
  }
}
