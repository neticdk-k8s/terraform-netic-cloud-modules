variable "nodepool" {
  type = object({
    cluster_id         = string
    name               = string
    vm_size            = string
    node_count         = number
    autoscale          = optional(bool, false)
    min_count          = optional(number, null)
    max_count          = optional(number, null)
    availability_zones = optional(list(string), [])
    vnet_subnet_id     = optional(string, null)
    labels             = optional(map(string), {})
    taints             = optional(list(string), []) # Azure format: "key=value:Effect"
    tags               = optional(map(string), {})
  })
  description = <<-EOT
    Azure AKS user node pool attached to an existing cluster.

      - cluster_id:         ID of the target AKS cluster.
      - vm_size:            Azure VM SKU, e.g. "Standard_D4ads_v6".
      - availability_zones: Zones the single pool is spread across (Azure handles
        multi-zone within one pool natively; no fan-out needed).
      - taints:             Azure taint strings, e.g. "dedicated=gpu:NoSchedule".
  EOT
}
