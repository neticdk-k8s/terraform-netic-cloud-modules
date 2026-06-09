
# https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_containerregistry#iam_enabled-1

resource "ovh_cloud_project_containerregistry" "registry" {
  count        = var.container_registry.deploy ? 1 : 0
  service_name = var.ovh_project_id
  region       = var.container_registry.region
  name         = var.container_registry.name
}

resource "ovh_cloud_project_containerregistry_ip_restrictions_management" "ip_restrictions" {
  count        = var.container_registry.deploy && length(var.ip_restrictions) > 0 ? 1 : 0

  service_name    = ovh_cloud_project_containerregistry.registry[0].service_name
  registry_id     = ovh_cloud_project_containerregistry.registry[0].id
  ip_restrictions = var.ip_restrictions
}

# IAM can be used instead — not both.
resource "ovh_cloud_project_containerregistry_user" "user" {
  for_each = var.container_registry.deploy ? { for user in var.registry_users : user.login => user } : {}

  service_name = ovh_cloud_project_containerregistry.registry[0].service_name
  registry_id  = ovh_cloud_project_containerregistry.registry[0].id

  login = each.value.login
  email = each.value.email
}
