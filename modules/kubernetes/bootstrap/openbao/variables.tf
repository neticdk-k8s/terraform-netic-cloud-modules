########################################
# Cluster identity & connection
########################################

variable "cluster_name" {
  description = <<-EOT
    Final, unique cluster name used for auth-backend path, KV paths and group
    names. The caller composes it (previously "<customer><region>-<simple>");
    the module treats it as an opaque identity string.
  EOT
  type        = string
}

variable "cluster_provider" {
  description = <<-EOT
    KV secrets mount / path segment that all policies are scoped under
    (e.g. "azure", "ovh"). Kept as a free-form string — it is NOT tied to the
    cloud the cluster runs on, only to the OpenBao mount layout.
  EOT
  type        = string
}

variable "create_kv_mount" {
  description = <<-EOT
    Mount a KV v2 engine at `cluster_provider`.

    true (default) suits one OpenBao per service cluster: nothing else creates
    the mount, and without it every read fails with "Secret does not exist"
    even though auth and policies are correct.

    Set false against a central, shared OpenBao where the mount is managed
    elsewhere — Terraform would otherwise fail with "path is already in use".

    The mount carries `prevent_destroy`, so removing it takes a deliberate
    `terraform state rm` rather than a stray plan.
  EOT
  type        = bool
  default     = true
}

variable "kubernetes_host" {
  description = "Kubernetes API server URL (the cluster module's cluster_endpoint output)."
  type        = string
}

variable "kubeconfig" {
  description = <<-EOT
    Raw kubeconfig for the target cluster. Used only to create the vault-auth
    token-reviewer ServiceAccount via kubectl, so the module stays provider-
    agnostic (works with AKS, OVH Managed Kubernetes, ...).
  EOT
  type        = string
  sensitive   = true
}

########################################
# OpenBao auth mount accessors
########################################

variable "alias_mount_accessor" {
  description = "Accessor of the OIDC (interactive user) auth mount. Defaults to the accessor of the mount at path \"oidc\"."
  type        = string
  default     = null
}

variable "alias_jwt_mount_accessor" {
  description = "Accessor of the JWT (automation) auth mount, used for the *_automated namespace groups."
  type        = string
  default     = null
}

########################################
# Namespaces (reference existing IdP groups by id)
########################################

variable "namespaces" {
  description = "Namespaces that get an interactive (OIDC) tenant policy+group. Map of namespace => IdP group id (alias_id)."
  type        = map(string)
  default     = {}
}

variable "namespaces_automated" {
  description = "Namespaces that get an automation (JWT) tenant policy+group. Map of namespace => IdP group id (alias_id)."
  type        = map(string)
  default     = {}
}

########################################
# Operator / provider groups
########################################

variable "operator_group_id" {
  description = "IdP group id for the operator_user group. null disables the operator group."
  type        = string
  default     = null
}

variable "provider_group_id" {
  description = "IdP group id for the provider_user group. null disables the provider group."
  type        = string
  default     = null
}

variable "additional_operator_group_policies" {
  description = "Additional policy names to attach to the operator group."
  type        = list(string)
  default     = []
}

########################################
# external-secrets & PKI
########################################

variable "external_secrets_policy_additional" {
  description = "Additional policy names to bind to the external-secrets role."
  type        = list(string)
  default     = []
}

variable "enable_pki_engine" {
  description = "Enable the PKI role + cert-manager policy/role (expects a mounted 'pki' engine)."
  type        = bool
  default     = false
}
