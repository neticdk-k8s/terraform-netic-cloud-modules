variable "public_ip" {
  type = object({
    service_name    = string
    ip              = string
    routed_to       = string
    prevent_destroy = optional(bool, false)
  })
  description = <<-EOT
    OVH Additional IP configuration. Attaches a pre-ordered OVH Additional IP
    (failover IP) to a compute instance — it does NOT create/order the IP.

      - service_name: OVH public cloud project ID (a.k.a. ovh_project_id).
      - ip:           The pre-ordered Additional IP address to attach.
      - routed_to:    GUID of the instance the IP should be routed to.
  EOT
}
