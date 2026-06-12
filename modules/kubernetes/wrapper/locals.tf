locals {
  # Provider is selected by which of cloud_settings.azure / cloud_settings.ovh is set
  cloud_provider = var.cloud_settings.ovh != null ? "ovh" : "azure"

  # Map T-shirt sizes to actual cloud VM SKUs / Flavors

  ## download openrc.sh from users
  ## run with 'source openrc.sh' to set env vars for terraform to use
  ##  openstack flavor list --sort-column RAM
  ## more info on flavor 'openstack flavor show d2-4'

  ## or https://www.ovhcloud.com/en/public-cloud/prices/
  node_sku_mapping = {
    azure = {
      # TEST & UDVIKLING (Burstable - B-serien)
      test-small    = "Standard_B1ms"       # 1 vCPU / 2 GiB RAM
      test-medium   = "Standard_B2s"        # 2 vCPU / 4 GiB RAM
      test-large    = "Standard_B2ms"       # 2 vCPU / 8 GiB RAM
      test-xl       = "Standard_B4ms"       # 4 vCPU / 16 GiB RAM

      # PRODUCTION GENERAL PURPOSE (1:4 ratio - AMD v6)
      small         = "Standard_D2ads_v6"   # 2 vCPU / 8 GiB RAM
      medium        = "Standard_D4ads_v6"   # 4 vCPU / 16 GiB RAM
      large         = "Standard_D8ads_v6"   # 8 vCPU / 32 GiB RAM
      xl            = "Standard_D16ads_v6"  # 16 vCPU / 64 GiB RAM

      # PRODUCTION MEMORY OPTIMIZED (1:8 ratio - AMD v6)
      memory-small  = "Standard_E4ads_v6"   # 4 vCPU / 32 GiB RAM
      memory-medium = "Standard_E8ads_v6"   # 8 vCPU / 64 GiB RAM
      memory-large  = "Standard_E16ads_v6"  # 16 vCPU / 128 GiB RAM
      memory-xl     = "Standard_E32ads_v6"  # 32 vCPU / 256 GiB RAM
    }
    ovh = {
      # TEST & UDVIKLING (Shared / Discovery - d2-serien)
      test-small    = "d2-2"                # 1 vCPU / 2 GiB RAM
      test-medium   = "d2-4"                # 2 vCPU / 4 GiB RAM
      test-large    = "d2-8"                # 4 vCPU / 8 GiB RAM
      test-xl       = "r3-16"               # 2 vCPU / 16 GiB RAM (not really a test SKU but we need something for 16 GiB RAM in testing)

      # PRODUCTION GENERAL PURPOSE (1:4 ratio - b3 NVMe)
      small         = "b3-8"                # 2 vCPU / 8 GiB RAM
      medium        = "b3-16"               # 4 vCPU / 16 GiB RAM
      large         = "b3-32"               # 8 vCPU / 32 GiB RAM
      xl            = "b3-64"               # 16 vCPU / 64 GiB RAM

      # PRODUCTION MEMORY OPTIMIZED (1:8 ratio - r3 NVMe)
      memory-small  = "r3-32"               # 4 vCPU / 32 GiB RAM
      memory-medium = "r3-64"               # 8 vCPU / 64 GiB RAM
      memory-large  = "r3-128"              # 16 vCPU / 128 GiB RAM
      memory-xl     = "r3-256"              # 32 vCPU / 256 GiB RAM
    }
  }

  # Resolving the architecture choices from the objects safely
  resolved_node_sku = lookup(
    local.node_sku_mapping[local.cloud_provider],
    var.node_config.node_size,
    var.node_config.node_size # Fallback if user passes a direct raw SKU instead of a T-shirt size
  )
}