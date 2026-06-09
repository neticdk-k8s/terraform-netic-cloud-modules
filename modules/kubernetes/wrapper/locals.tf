locals {
  # Map T-shirt sizes to actual cloud VM SKUs / Flavors

  ## download openrc.sh from users
  ## run with 'source openrc.sh' to set env vars for terraform to use
  ##  openstack flavor list --sort-column RAM
  ## more info on flavor 'openstack flavor show d2-4'

  ## or https://www.ovhcloud.com/en/public-cloud/prices/
  node_sku_mapping = {
    azure = {
      small  = "Standard_B2ms"
      medium = "Standard_D2s_v5"
      large  = "Standard_D4s_v5"
    }
    ovh = {
      small  = "d2-4"
      medium = "b3-16"
      large  = "b2-30"
    }
  }

  # Resolving the architecture choices from the objects safely
  resolved_node_sku = lookup(
    local.node_sku_mapping[var.cloud_settings.cloud_provider],
    var.node_config.node_size,
    var.node_config.node_size # Fallback if user passes a direct raw SKU instead of a T-shirt size
  )
}