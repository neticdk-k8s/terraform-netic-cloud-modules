variable "gateway" {
  type = object({
    name         = string
    service_name = string
    region       = string
    model        = optional(string, "s")
    subnet_ids   = list(string)
  })
  description = <<-EOT
    OVH Public Cloud Gateway configuration. Creates a managed gateway that gives
    instances on one or more private networks outbound internet access via SNAT.

      - name:         Gateway name.
      - service_name: OVH public cloud project ID (a.k.a. ovh_project_id).
      - region:       OVH region, e.g. "GRA11" (all subnets must be in this region).
      - model:        Gateway size: "s", "m" or "l" (throughput tiers). Default "s".
      - subnet_ids:   OpenStack subnet UUIDs to attach (network module `subnet_ids[region]`).
                      The first is the primary attachment; any further subnets are added
                      as extra interfaces so the gateway also SNATs those networks. Each
                      subnet's parent network is looked up automatically.
  EOT

  validation {
    condition     = length(var.gateway.subnet_ids) >= 1
    error_message = "gateway.subnet_ids must contain at least one subnet (the primary)."
  }
}
