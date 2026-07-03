resource "azurerm_storage_account" "storage" {
  name                     = var.storage.name
  resource_group_name      = var.storage.resource_group
  location                 = var.storage.location
  account_tier             = "Standard"
  account_replication_type = var.storage.replication_type
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = var.storage.versioning

    dynamic "delete_retention_policy" {
      for_each = var.storage.retention_days > 0 ? [1] : []
      content {
        days = var.storage.retention_days
      }
    }
  }

  tags = var.storage.tags
}

resource "azurerm_storage_container" "container" {
  name                  = var.storage.container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
