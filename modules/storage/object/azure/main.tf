resource "azurerm_storage_account" "storage" {
  name                     = var.name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = var.versioning

    dynamic "delete_retention_policy" {
      for_each = var.retention_days > 0 ? [1] : []
      content {
        days = var.retention_days
      }
    }
  }

  tags = {
    managed-by = "terraform"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
