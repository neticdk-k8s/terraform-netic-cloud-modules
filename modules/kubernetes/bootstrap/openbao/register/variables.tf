variable "kubeconfig" {
  description = "Raw kubeconfig for the cluster OpenBao runs in."
  type        = string
  sensitive   = true
}

variable "root_token" {
  description = "Token used for the registration (e.g. module.openbao_init.root_token)."
  type        = string
  sensitive   = true
}

variable "cluster_provider" {
  description = "KV v2 mount and first path segment, e.g. \"netic-platform-ovh\"."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name in OpenBao paths. Auth path: <cluster_provider>/k8s/<cluster_name>."
  type        = string
}

variable "seed_secrets" {
  description = <<-EOT
    KV secrets written ONLY if missing, keyed by path under k8s/<cluster_name>/.
      static    — fixed values (not secret; stored in state as plain text)
      generated — field names that get a random 32-char alphanumeric value,
                  generated at apply time and never stored in state
    Example:
      "netic-keycloak-system/keycloak" = {
        static    = { db_username = "keycloak" }
        generated = ["db_password"]
      }
  EOT
  type = map(object({
    static    = optional(map(string), {})
    generated = optional(list(string), [])
  }))
  default = {}
}

variable "namespace" {
  description = "Namespace OpenBao is deployed in."
  type        = string
  default     = "netic-vault-system"
}

variable "pod_name" {
  description = "Pod to exec into."
  type        = string
  default     = "openbao-0"
}

variable "container_name" {
  description = "Container with the bao binary."
  type        = string
  default     = "openbao"
}

variable "service_name" {
  description = "OpenBao Service. Used for BAO_ADDR — the server certificate has DNS SANs only."
  type        = string
  default     = "openbao"
}

variable "api_port" {
  description = "OpenBao API port."
  type        = number
  default     = 8200
}
