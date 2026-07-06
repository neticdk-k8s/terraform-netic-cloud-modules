resource "ovh_cloud_project_failover_ip_attach" "aip" {
  count        = var.public_ip.prevent_destroy ? 0 : 1
  service_name = var.public_ip.service_name
  ip           = var.public_ip.ip
  routed_to    = var.public_ip.routed_to
}

resource "ovh_cloud_project_failover_ip_attach" "aip_protected" {
  count        = var.public_ip.prevent_destroy ? 1 : 0
  service_name = var.public_ip.service_name
  ip           = var.public_ip.ip
  routed_to    = var.public_ip.routed_to

  lifecycle {
    prevent_destroy = true
  }
}
