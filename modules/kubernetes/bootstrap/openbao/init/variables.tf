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

variable "service_name" {
  description = "OpenBao Service name. Used to build the API address — the server certificate carries DNS SANs only, so an IP address fails validation."
  type        = string
  default     = "openbao"
}

variable "pod_name" {
  description = "Pod to exec into. The first replica of the StatefulSet."
  type        = string
  default     = "openbao-0"
}

variable "container_name" {
  description = "Container inside the pod that runs the bao binary."
  type        = string
  default     = "openbao"
}

variable "api_port" {
  description = "Port the OpenBao API listens on."
  type        = number
  default     = 8200
}

variable "ca_cert_path" {
  description = "Path inside the container to the CA certificate for the server's TLS listener (BAO_CACERT)."
  type        = string
  default     = "/openbao/userconfig/openbao-server-tls/ca.crt"
}

variable "api_timeout_seconds" {
  description = "How long to wait for the OpenBao API to answer. On a fresh cluster GitOps still has to reconcile the HelmRelease and pull the image, so the pod does not exist for the first minutes."
  type        = number
  default     = 600
}

variable "recovery_shares" {
  description = <<-EOT
    Number of recovery key shares to generate. With auto-unseal the seal is held
    by the KMS, so these are *recovery* keys, not unseal keys — they exist to
    regain control if the KMS key is lost, and are shown exactly once.
  EOT
  type        = number
  default     = 5

  validation {
    condition     = var.recovery_shares >= 1
    error_message = "recovery_shares must be at least 1."
  }
}

variable "recovery_threshold" {
  description = "How many recovery shares are needed to act. Must not exceed recovery_shares."
  type        = number
  default     = 3

  validation {
    condition     = var.recovery_threshold >= 1
    error_message = "recovery_threshold must be at least 1."
  }
}

variable "state_file" {
  description = <<-EOT
    Where to write the init JSON (root token + recovery keys). Defaults to a
    per-namespace filename in the root working directory so two clusters in one
    root cannot overwrite each other's credentials.

    This file holds the most privileged credentials the cluster has. Persist the
    module's outputs to a real secret store and delete it — see the README.
  EOT
  type        = string
  default     = null
}
