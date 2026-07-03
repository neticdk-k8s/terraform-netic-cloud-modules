output "id" {
  description = "Managed disk resource ID — pass to a VM via vm.azure.data_disks[].disk_id"
  value       = azurerm_managed_disk.disk.id
}

output "name" {
  description = "Disk name"
  value       = azurerm_managed_disk.disk.name
}
