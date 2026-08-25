variable "policy_name" {
  description = "Name of the OpenBao policy to create"
  type        = string
}

variable "policy_content" {
  description = "Actual ACL policy (HCL)"
  type        = string
}

variable "group_name" {
  description = "Name of the OpenBao external identity group to create"
  type        = string
}

variable "alias_id" {
  description = <<-EOT
    IdP group identifier used as the alias name on the OpenBao external group,
    i.e. the object/UUID your OIDC/JWT provider puts in the token's groups claim
    (Entra ID object_id, Keycloak group id, ...). Provider-agnostic: whatever
    creates the group upstream must feed its id in here.
  EOT
  type        = string
}

variable "alias_mount_accessor" {
  description = "Accessor of the OIDC (user) auth mount. Used when alias_jwt_mount_accessor is null."
  type        = string
  default     = null
}

variable "alias_jwt_mount_accessor" {
  description = "Accessor of the JWT (automation) auth mount. When set, the group is created as a '-jwt' group aliased to this mount instead of the OIDC mount."
  type        = string
  default     = null
}

variable "additional_operator_group_policies" {
  description = "Additional policy names to attach to the group besides the one created here."
  type        = list(string)
  default     = []
}
