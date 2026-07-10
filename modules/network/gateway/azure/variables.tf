variable "gateway" {
  type = object({
    name                    = string
    location                = string
    resource_group          = string
    public_ip_id            = string
    subnet_ids              = optional(list(string), [])
    idle_timeout_in_minutes = optional(number, 4)
    tags                    = optional(map(string), {})
  })
  description = <<-EOT
    Azure NAT Gateway configuration. Gives VMs on the associated subnet(s)
    outbound internet access via a single, stable public IP (SNAT).

      - name:                    NAT gateway name.
      - location:                Azure region, e.g. "westeurope".
      - resource_group:          Resource group name.
      - public_ip_id:            Resource ID of a Standard public IP (see public-ip module)
                                 used as the gateway's outbound address.
      - subnet_ids:              Subnet IDs to route outbound through the gateway.
      - idle_timeout_in_minutes: SNAT idle timeout (default 4).
      - tags:                    Tags on the NAT gateway.
  EOT
}
