# A standalone block-storage volume. Created separately from the VM so the
# disk's lifecycle is decoupled — it survives VM rebuilds. Attach it via
# vm.ovh.disk_ids on the vm module.
resource "openstack_blockstorage_volume_v3" "disk" {
  name        = var.disk.name
  size        = var.disk.size_gb
  volume_type = var.disk.volume_type
}
