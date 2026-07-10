variable "nodepool" {
  type = object({
    service_name        = string
    kube_id             = string
    name                = string
    flavor              = string
    desired_nodes       = number
    autoscale           = optional(bool, false)
    min_nodes           = optional(number, null)
    max_nodes           = optional(number, null)
    availability_zones  = optional(list(string), [])
    monthly_billed      = optional(bool, false)
    anti_affinity       = optional(bool, false)
    attach_floating_ips = optional(bool, false) # public floating IP per node (egress without a gateway/router)
    labels              = optional(map(string), {})
    taints              = optional(list(any), [])
  })
  description = <<-EOT
    OVH Managed Kubernetes node pool.

      - service_name: OVH public cloud project ID (ovh_project_id).
      - kube_id:      ID of the target cluster.
      - flavor:       OVH flavor name, e.g. "b3-8".
      - availability_zones: In a 3-AZ region, one pool is created PER zone
        (name suffixed with the zone short code). desired/min/max apply per pool.
        Leave empty in single-AZ regions.
  EOT
}
