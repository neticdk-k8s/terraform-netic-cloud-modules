# A standalone managed disk. Created separately from the VM so the disk's
# lifecycle is decoupled — it survives VM rebuilds. Attach it via
# vm.azure.data_disks on the vm module.
resource "azurerm_managed_disk" "disk" {
  name                 = var.disk.name
  location             = var.disk.location
  resource_group_name  = var.disk.resource_group
  storage_account_type = var.disk.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.disk.size_gb
  zone                 = var.disk.zone
  tags                 = var.disk.tags
}
