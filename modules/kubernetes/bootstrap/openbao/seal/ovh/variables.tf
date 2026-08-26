variable "kubeconfig" {
  description = "Raw kubeconfig for the cluster OpenBao runs in. Uses kubectl only, so no cloud-specific CLI is required."
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Namespace OpenBao is deployed in."
  type        = string
  default     = "netic-vault-system"
}

variable "namespace_timeout_seconds" {
  description = "How long to wait for GitOps to create the namespace before falling back to creating it. On a fresh cluster Terraform normally gets here before Flux has reconciled."
  type        = number
  default     = 180
}

variable "create_namespace" {
  description = <<-EOT
    Create the namespace if it still does not exist after the wait. Safe by
    default: the seal Secret must exist before OpenBao starts, and an early
    namespace also unblocks the GitOps Kustomization that carries OpenBao's
    Certificate — that Kustomization cannot apply until the namespace is there.
    Flux adopts the namespace on its next reconcile.

    Set false to fail instead, if namespace creation must stay with GitOps.
  EOT
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name of the seal Secret. Must match the Helm chart's secretName for both extraSecretEnvironmentVars and the seal volume."
  type        = string
  default     = "openbao-seal"
}

variable "okms" {
  description = <<-EOT
    OVHcloud KMS (OKMS) coordinates for auto-unseal:
      endpoint — OKMS REST API endpoint, e.g. "https://eu-west-gra.okms.ovh.net"
      kms_id   — UUID of the OKMS *domain* (your keyvault module's `id` output)
      key_id   — UUID of the service key inside that domain. Must be an AES key
                 that supports both encrypt and decrypt.
    Note kms_id and key_id are two different UUIDs — the domain and the key.
  EOT
  type = object({
    endpoint = string
    kms_id   = string
    key_id   = string
  })

  validation {
    condition     = startswith(var.okms.endpoint, "https://")
    error_message = "okms.endpoint must be an https:// URL, e.g. \"https://eu-west-gra.okms.ovh.net\"."
  }

  validation {
    condition     = var.okms.kms_id != var.okms.key_id
    error_message = "okms.kms_id and okms.key_id are the same value. They are two different UUIDs — the OKMS domain and the service key inside it."
  }
}

variable "auth" {
  description = <<-EOT
    How OpenBao authenticates to OKMS. Set exactly one of the two modes:

      mTLS (recommended) — client_cert_pem + client_key_pem
        The certificate is yours: OVH only signs it. Create it with
        `ovh_okms_credential`; see the README for a CSR-based example where the
        private key never leaves your machine. The PEMs are written into the
        Secret and mounted as files, because OpenBao's OVHCLOUDKMS_CLIENT_CERT /
        _CLIENT_KEY take file PATHS, not inline content.

      Token — token
        An OVHcloud Personal Access Token created in the OVH Manager. Simpler,
        but a long-lived bearer credential.

    Pass raw PEM / raw token. This module base64-encodes for the Secret itself.
  EOT
  type = object({
    token           = optional(string)
    client_cert_pem = optional(string)
    client_key_pem  = optional(string)
  })
  sensitive = true

  validation {
    condition = (
      (var.auth.token != null && var.auth.token != "") !=
      (var.auth.client_cert_pem != null && var.auth.client_key_pem != null)
    )
    error_message = "Set exactly one auth mode: either auth.token, or both auth.client_cert_pem and auth.client_key_pem."
  }

  validation {
    condition = (
      (var.auth.client_cert_pem == null) == (var.auth.client_key_pem == null)
    )
    error_message = "mTLS needs both auth.client_cert_pem and auth.client_key_pem — one of them is missing."
  }

  validation {
    condition     = var.auth.client_cert_pem == null || can(regex("BEGIN CERTIFICATE", var.auth.client_cert_pem))
    error_message = "auth.client_cert_pem does not look like a PEM certificate (no BEGIN CERTIFICATE block). Pass the certificate contents, not a file path or a base64 blob."
  }

  validation {
    condition     = var.auth.client_key_pem == null || can(regex("BEGIN (RSA |EC )?PRIVATE KEY", var.auth.client_key_pem))
    error_message = "auth.client_key_pem does not look like a PEM private key. Note OVH only returns the private key at creation time (`private_key_pem`, never retrievable later) — a credential made in the OVH portal cannot supply it."
  }

  # An exported-but-empty TF_VAR_* silently overrides a non-empty default.
  validation {
    condition     = var.auth.token == null || length(trimspace(coalesce(var.auth.token, " "))) > 0
    error_message = "auth.token is set but empty. An exported-but-empty TF_VAR_* overrides any default — check `printenv`."
  }

  # A token that base64-decodes to a JWT was encoded once too many times.
  validation {
    condition     = var.auth.token == null || !try(startswith(base64decode(var.auth.token), "eyJ"), false)
    error_message = "auth.token appears to be base64-encoded (it decodes to a JWT). Pass the raw token — this module base64-encodes it for the Secret itself."
  }

  # The registration module writes the cluster's `vault-auth` ServiceAccount
  # token to vault-sa-secret-*.json in the same working directory. It is also a
  # JWT and easy to grab by mistake, but it authenticates OpenBao *to
  # Kubernetes* and can never unseal.
  validation {
    condition = var.auth.token == null || !try(
      strcontains(
        base64decode(format("%s%s",
          replace(replace(split(".", var.auth.token)[1], "-", "+"), "_", "/"),
          substr("===", 0, (4 - length(split(".", var.auth.token)[1]) % 4) % 4)
        )),
        "kubernetes/serviceaccount"
      ),
      false
    )
    error_message = "auth.token is a Kubernetes ServiceAccount token (iss=kubernetes/serviceaccount), not an OVHcloud token — likely picked up from vault-sa-secret-*.json. Auto-unseal needs an OVHcloud credential."
  }
}

variable "statefulset_name" {
  description = "StatefulSet to restart when the seal values change. Env vars and mounted files are only read at container start, so an update is a no-op without a restart."
  type        = string
  default     = "openbao"
}

variable "restart_statefulset" {
  description = "Roll the StatefulSet whenever the seal Secret's contents change."
  type        = bool
  default     = true
}
