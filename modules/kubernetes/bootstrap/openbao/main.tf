locals {
  cluster_name             = var.cluster_name
  kubernetes_host          = var.kubernetes_host
  alias_jwt_mount_accessor = var.alias_jwt_mount_accessor

  # The OIDC accessor is only needed to alias interactive user groups
  # (namespaces / operator / provider). For a pure external-secrets
  # registration we must NOT look up an "oidc" mount that may not exist on
  # this OpenBao — doing so unconditionally would fail the plan.
  needs_oidc_lookup = var.alias_mount_accessor == null && (
    length(var.namespaces) > 0 ||
    var.operator_group_id != null ||
    var.provider_group_id != null
  )

  alias_mount_accessor = var.alias_mount_accessor != null ? var.alias_mount_accessor : (
    local.needs_oidc_lookup ? data.vault_auth_backend.oidc[0].accessor : null
  )

  # Per-cluster filename so two clusters configured in the same root can't
  # clobber each other's token secret on disk.
  sa_secret_file = "${path.cwd}/vault-sa-secret-${var.cluster_name}.json"
}

data "vault_auth_backend" "oidc" {
  count = local.needs_oidc_lookup ? 1 : 0
  path  = "oidc"
}

########################################
# KV secrets engine
########################################

# The policies below grant access to <cluster_provider>/data/... and
# <cluster_provider>/metadata/..., which only exist once a KV **v2** engine is
# mounted at that path.
#
# The original module assumed a central, shared OpenBao where someone else had
# already mounted it. Running one OpenBao per service cluster, nobody does — and
# the symptom is misleading: auth succeeds, the SecretStore reports "store
# validated", and every read fails with "Secret does not exist" rather than a
# permission error.

# Split in two because `lifecycle` accepts only literals — `prevent_destroy =
# var.protect_kv_mount` is rejected at parse time. `count` picks exactly one, so
# at most one of these ever exists. Same workaround as network/floating-ip/ovh
# and network/public-ip/ovh.
#
# WARNING: flipping protect_kv_mount moves the mount between these two addresses,
# which plans as destroy + create and would delete every secret under it. Use
# `tofu state mv` to relocate it instead of applying the change.
locals {
  # Shared so the two blocks below cannot drift apart.
  kv_mount = {
    path        = var.cluster_provider
    type        = "kv"
    options     = { version = "2" }
    description = "KV v2 store for clusters registered under ${var.cluster_provider}"
  }
}

resource "vault_mount" "kv" {
  count = var.create_kv_mount && !var.protect_kv_mount ? 1 : 0

  path        = local.kv_mount.path
  type        = local.kv_mount.type
  options     = local.kv_mount.options
  description = local.kv_mount.description
}

# The mount holds every secret for every cluster under this path. Where it
# outlives this deployment, Terraform must never be able to take it down and
# take the data with it.
resource "vault_mount" "kv_protected" {
  count = var.create_kv_mount && var.protect_kv_mount ? 1 : 0

  path        = local.kv_mount.path
  type        = local.kv_mount.type
  options     = local.kv_mount.options
  description = local.kv_mount.description

  lifecycle {
    prevent_destroy = true
  }
}

########################################
# Kubernetes auth backend + token reviewer
########################################

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "${var.cluster_provider}/k8s/${local.cluster_name}"
}

# Provider-agnostic: create the token-reviewer ServiceAccount via kubectl using
# the passed kubeconfig, instead of a cloud-specific CLI (az/ovh).
resource "null_resource" "vault_auth" {
  triggers = {
    cluster_name = var.cluster_name
    exists       = fileexists(local.sa_secret_file)

    # Afgørende ved genopbygning: cluster_name er den samme streng før og efter
    # et destroy/redeploy, og filen findes stadig fra sidste gang — så uden
    # dette ville scriptet aldrig køre igen, og OpenBao ville blive konfigureret
    # med det GAMLE clusters token-reviewer og CA.
    #
    # Symptomet er ondskabsfuldt: auth-backenden ser korrekt ud, kubernetes_host
    # er rigtig, men alle logins fejler, fordi OpenBao validerer mod det nye
    # cluster med credentials fra det gamle. API-hosten er unik pr. cluster og
    # er derfor det rigtige signal.
    kubernetes_host = var.kubernetes_host
  }

  # namespaces_automated builds JWT (automation) groups, which can only be
  # aliased to a JWT auth mount. Fail early with a clear message instead of the
  # cryptic "mount_accessor is required" from the group-policy submodule.
  lifecycle {
    precondition {
      condition     = length(var.namespaces_automated) == 0 || var.alias_jwt_mount_accessor != null
      error_message = "namespaces_automated is set but alias_jwt_mount_accessor is null. Pass the JWT auth mount accessor (e.g. data.vault_auth_backend.jwt.accessor), or remove namespaces_automated."
    }
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/vault-sa.sh ${local.sa_secret_file}"
    working_dir = path.cwd

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
    }
  }
}

data "local_sensitive_file" "vault_sa" {
  filename   = local.sa_secret_file
  depends_on = [null_resource.vault_auth]
}

locals {
  vault_sa = try(jsondecode(data.local_sensitive_file.vault_sa.content), {
    data = {
      "ca.crt" = ""
      "token"  = ""
    }
  })
}

resource "vault_kubernetes_auth_backend_config" "vault_config" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = local.kubernetes_host
  kubernetes_ca_cert = base64decode(local.vault_sa["data"]["ca.crt"])
  token_reviewer_jwt = base64decode(local.vault_sa["data"]["token"])
}

########################################
# external-secrets
########################################

resource "vault_policy" "external_secrets_policy" {
  name   = "${var.cluster_provider}/k8s/${local.cluster_name}/external-secrets"
  policy = <<EOT
path "/${var.cluster_provider}/data/k8s/${local.cluster_name}/{{ identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.service_account_namespace }}/*" {
  capabilities = [ "read", "list" ]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "external_secrets_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = concat([vault_policy.external_secrets_policy.name], var.external_secrets_policy_additional)
}

########################################
# PKI / cert-manager (optional)
########################################

resource "vault_policy" "policy" {
  count = var.enable_pki_engine ? 1 : 0

  name   = "${var.cluster_provider}/k8s/${local.cluster_name}/cert-manager"
  policy = <<EOT
path "pki/sign/${var.cluster_provider}-k8s-${local.cluster_name}-cert-manager" {
  capabilities = [ "update" ]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "role" {
  count = var.enable_pki_engine ? 1 : 0

  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["netic-ingress-system", "netic-security-system"]
  token_ttl                        = 3600
  token_policies                   = ["${var.cluster_provider}/k8s/${local.cluster_name}/cert-manager"]
}

resource "vault_pki_secret_backend_role" "cert_manager" {
  count = var.enable_pki_engine ? 1 : 0

  backend            = "pki"
  name               = "${var.cluster_provider}-k8s-${local.cluster_name}-cert-manager"
  key_type           = "rsa"
  key_bits           = 4096
  allowed_domains    = concat(["observability.netic-external", "${var.cluster_provider}_${local.cluster_name}"])
  allow_subdomains   = true
  allow_bare_domains = true
  require_cn         = false
  enforce_hostnames  = false

  lifecycle {
    ignore_changes = [
      key_usage,
    ]
  }
}

########################################
# Tenant namespace policies (reference existing IdP groups)
########################################

# Interactive (OIDC) tenant groups.
module "vault_policy_namespace" {
  source   = "./group-policy"
  for_each = var.namespaces

  policy_name              = "${var.cluster_provider}/k8s/${local.cluster_name}/tenant.${each.key}"
  policy_content           = <<EOT
path "${var.cluster_provider}/metadata/+" {
	capabilities = [ "list" ]
}

path "${var.cluster_provider}/metadata/k8s" {
	capabilities = [ "list" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}" {
	capabilities = [ "list", "read" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}" {
	capabilities = [ "list","read" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/+" {
	capabilities = [ "list", "read", "create", "update", "delete" ]
}

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+" {
	capabilities = [ "create", "update", "delete" ]
}

# Legacy "folder" support
path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/+/*" {
	capabilities = [ "list", "read", "create", "update", "delete" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+/*" {
	capabilities = [ "create", "update", "delete" ]
}

#
# "Application" subpaths

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+/restricted/*" {
	capabilities = [ "create", "update", "delete" ]
}

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+/unrestricted/*" {
	capabilities = [ "create", "read", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/+/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+/automated/*" {
	capabilities = [ "deny" ]
}

#
# "root" subpaths
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/restricted/*" {
	capabilities = [ "create", "update", "delete" ]
}

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/unrestricted/*" {
	capabilities = [ "create", "read", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/automated/*" {
	capabilities = [ "deny" ]
}
EOT
  group_name               = "${var.cluster_provider}_${local.cluster_name}_tenant.${each.key}"
  alias_id                 = each.value
  alias_mount_accessor     = local.alias_mount_accessor
  alias_jwt_mount_accessor = null
}

# Automation (JWT) tenant groups.
module "vault_policy_namespace_jwt" {
  source   = "./group-policy"
  for_each = var.namespaces_automated

  policy_name              = "${var.cluster_provider}/k8s/${local.cluster_name}/tenant.${each.key}-jwt"
  policy_content           = <<EOT
#
# "Application" subpaths
path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/+/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/+/automated/*" {
	capabilities = [ "list", "create", "update", "delete" ]
}

#
# "root" subpaths
path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/${each.key}/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/${each.key}/automated/*" {
	capabilities = [ "list", "create", "update", "delete" ]
}
EOT
  group_name               = "${var.cluster_provider}_${local.cluster_name}_tenant.${each.key}"
  alias_id                 = each.value
  alias_mount_accessor     = null
  alias_jwt_mount_accessor = local.alias_jwt_mount_accessor
}

########################################
# Operator / provider groups
########################################

module "vault_policy_operator" {
  count  = var.operator_group_id != null ? 1 : 0
  source = "./group-policy"

  policy_name                        = "${var.cluster_provider}/k8s/${local.cluster_name}/operator_user"
  policy_content                     = <<EOT
path "${var.cluster_provider}/*" {
  capabilities = [ "list" ]
}

# Allow create,update,delete of secrets for all namespace in development environments
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/*" {
  capabilities = [ "read", "create", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/+/*" {
  capabilities = [ "list", "read", "create", "update", "delete" ]
}
EOT
  group_name                         = "${var.cluster_provider}_${local.cluster_name}_operator_user"
  alias_id                           = var.operator_group_id
  alias_mount_accessor               = local.alias_mount_accessor
  alias_jwt_mount_accessor           = null
  additional_operator_group_policies = var.additional_operator_group_policies
}

module "vault_policy_provider" {
  count  = var.provider_group_id != null ? 1 : 0
  source = "./group-policy"

  policy_name              = "${var.cluster_provider}/k8s/${local.cluster_name}/provider_user"
  policy_content           = <<EOT
path "${var.cluster_provider}/*" {
  capabilities = [ "list" ]
}

# Allow create,update,delete of secrets for all namespace in development environments
# Read is here for legacy support should be removed 01/01/2024
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/*" {
  capabilities = [ "read", "create", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/+/*" {
  capabilities = [ "list", "read", "create", "update", "delete" ]
}

#
# "Application" subpaths

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/+/restricted/*" {
	capabilities = [ "create", "update", "delete" ]
}

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/+/unrestricted/*" {
	capabilities = [ "create", "read", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/+/+/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/+/automated/*" {
	capabilities = [ "deny" ]
}

#
# "root" subpaths

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/restricted/*" {
	capabilities = [ "create", "update", "delete" ]
}

path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/unrestricted/*" {
	capabilities = [ "create", "read", "update", "delete" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/+/automated/*" {
	capabilities = [ "list", "read" ]
}
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/+/automated/*" {
	capabilities = [ "deny" ]
}


# Restricted namespaces
path "${var.cluster_provider}/data/k8s/${local.cluster_name}/netic-*" {
  capabilities = [ "deny" ]
}

path "${var.cluster_provider}/metadata/k8s/${local.cluster_name}/netic-*" {
  capabilities = [ "deny" ]
}
EOT
  group_name               = "${var.cluster_provider}_${local.cluster_name}_provider_user"
  alias_id                 = var.provider_group_id
  alias_mount_accessor     = local.alias_mount_accessor
  alias_jwt_mount_accessor = null
}
