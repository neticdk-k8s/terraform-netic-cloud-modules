variable "kubeconfig" {
  type        = string
  sensitive   = true
  description = "Raw kubeconfig content for the target cluster. Used instead of cloud-specific CLI tools so the module works with any provider (Azure, OVH, etc.)"
}

variable "cluster_repo" {
  type        = string
  description = "The Git URL for the cluster repository"
}

variable "bootstrap_path" {
  type        = string
  description = "The path for cluster reconciliation within the cluster repository"
}

variable "git_auth" {
  description = "Git credentials provisioned into 'netic-gitops-system' namespace. Expects keys 'netic' (username/password) and 'kubernetes-config' (identity)."
  type = map(object({
    username = optional(string, "")
    password = optional(string, "")
    identity = optional(string, "")
  }))
}
