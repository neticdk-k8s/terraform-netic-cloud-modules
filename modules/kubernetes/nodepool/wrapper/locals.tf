locals {
  cloud_provider = var.nodepool.ovh != null ? "ovh" : "azure"

  # Same T-shirt size → SKU/flavor mapping as the cluster wrapper, so pools added
  # later use identical sizing. Falls back to the given value as a raw SKU.
  node_sku_mapping = {
    azure = {
      test-small  = "Standard_B1ms"
      test-medium = "Standard_B2s"
      test-large  = "Standard_B2ms"
      test-xl     = "Standard_B4ms"

      small  = "Standard_D2ads_v6"
      medium = "Standard_D4ads_v6"
      large  = "Standard_D8ads_v6"
      xl     = "Standard_D16ads_v6"

      memory-small  = "Standard_E4ads_v6"
      memory-medium = "Standard_E8ads_v6"
      memory-large  = "Standard_E16ads_v6"
      memory-xl     = "Standard_E32ads_v6"
    }
    ovh = {
      test-small  = "d2-2"
      test-medium = "d2-4"
      test-large  = "d2-8"
      test-xl     = "r3-16"

      small  = "b3-8"
      medium = "b3-16"
      large  = "b3-32"
      xl     = "b3-64"

      memory-small  = "r3-32"
      memory-medium = "r3-64"
      memory-large  = "r3-128"
      memory-xl     = "r3-256"
    }
  }

  resolved_node_sku = lookup(
    local.node_sku_mapping[local.cloud_provider],
    var.nodepool.node_size,
    var.nodepool.node_size
  )

  # Azure node taints are strings ("key=value:Effect"); OVH takes the objects as-is.
  azure_taints = [for t in var.nodepool.taints : "${t.key}=${t.value}:${t.effect}"]
}
