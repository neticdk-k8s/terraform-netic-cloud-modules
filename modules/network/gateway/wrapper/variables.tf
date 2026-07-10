variable "gateway" {
  type = object({
    name       = string
    region     = string                     # Azure location / OVH region
    subnet_ids = optional(list(string), []) # Subnets served by the gateway (OVH: first = primary, rest = extra interfaces)
    tags       = optional(map(string), {})  # Applied where the cloud supports it (Azure) — OVH gateways have no tags

    azure = optional(object({
      resource_group          = string
      public_ip_id            = string
      idle_timeout_in_minutes = optional(number, 4)
    }), null)

    ovh = optional(object({
      project_id = string
      model      = optional(string, "s")
    }), null)
  })
  description = <<-EOT
    Gateway for outbound external (internet) access. Set exactly one of
    gateway.azure or gateway.ovh — never both. Common settings live at the top
    level; only genuinely cloud-specific settings sit under azure/ovh.

    Both give private-network VMs a stable outbound public IP via SNAT:
      - Azure creates an azurerm_nat_gateway, binds public_ip_id and associates subnet_ids.
      - OVH creates an ovh_cloud_project_gateway on subnet_ids (extra subnets become interfaces).
  EOT

  validation {
    condition     = (var.gateway.ovh != null) != (var.gateway.azure != null)
    error_message = "Exactly one of gateway.ovh or gateway.azure must be set."
  }

  validation {
    condition     = var.gateway.ovh == null || length(var.gateway.subnet_ids) >= 1
    error_message = "OVH gateways require at least one entry in gateway.subnet_ids (the primary subnet)."
  }
}
