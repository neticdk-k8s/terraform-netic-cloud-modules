output "id" {
  description = "Volume UUID — pass to a VM via vm.ovh.disk_ids"
  value       = openstack_blockstorage_volume_v3.disk.id
}

output "name" {
  description = "Volume name"
  value       = openstack_blockstorage_volume_v3.disk.name
}
