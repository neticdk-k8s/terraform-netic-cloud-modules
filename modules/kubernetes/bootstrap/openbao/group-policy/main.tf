# A single OpenBao ACL policy plus an external identity group aliased to an
# upstream IdP group. Provider-agnostic: the IdP group id is passed in via
# alias_id — this module never creates the IdP group itself.

resource "vault_policy" "policy" {
  name   = var.policy_name
  policy = var.policy_content
}

# OIDC (interactive user) group — created when no JWT accessor is given.
resource "vault_identity_group" "group" {
  count    = var.alias_jwt_mount_accessor == null ? 1 : 0
  name     = var.group_name
  type     = "external"
  policies = concat([vault_policy.policy.name], var.additional_operator_group_policies)
}

# JWT (automation) group — created when a JWT accessor is given.
resource "vault_identity_group" "group_jwt" {
  count    = var.alias_jwt_mount_accessor != null ? 1 : 0
  name     = "${var.group_name}-jwt"
  type     = "external"
  policies = concat([vault_policy.policy.name], var.additional_operator_group_policies)
}

resource "vault_identity_group_alias" "group_alias" {
  count          = var.alias_jwt_mount_accessor == null ? 1 : 0
  name           = var.alias_id
  mount_accessor = var.alias_mount_accessor
  canonical_id   = vault_identity_group.group[0].id
}

resource "vault_identity_group_alias" "group_jwt_alias" {
  count          = var.alias_jwt_mount_accessor != null ? 1 : 0
  name           = var.alias_id
  mount_accessor = var.alias_jwt_mount_accessor
  canonical_id   = vault_identity_group.group_jwt[0].id
}
