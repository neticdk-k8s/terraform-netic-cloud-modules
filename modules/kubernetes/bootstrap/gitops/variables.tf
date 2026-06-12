variable "kubeconfig" {
  type        = string
  sensitive   = true
  description = "Raw kubeconfig content for the target cluster. Used instead of cloud-specific CLI tools so the module works with any provider (Azure, OVH, etc.)"
}

variable "gotk_repo" {
  type        = string
  description = "Git URL for the gotk-bootstrap repo (Flux components)"
  default     = "git.netic.dk/scm/pd/gotk-bootstrap-k8s.git"
}

variable "gotk_path" {
  type        = string
  description = "Path within gotk_repo containing gotk-components.yaml"
  default     = "gotk"
}

variable "cluster_repo" {
  type        = string
  description = "Git URL for the cluster config repo (bootstrapped with kustomize)"
}

variable "bootstrap_path" {
  type        = string
  description = "Path within cluster_repo to apply with kustomize"
}

variable "git_ssh_port" {
  type        = number
  description = "SSH port on the git server, used for ssh-keyscan when patching known_hosts (7999 = Bitbucket Server default)"
  default     = 7999
}

variable "keyscan_image" {
  type        = string
  description = "Container image used for the in-cluster ssh-keyscan pod. Must have ssh-keyscan preinstalled — runtime package install fails on clusters where pod egress to package CDNs is restricted."
  default     = "ghcr.io/linuxserver/openssh-server:latest"
}

variable "git_auth" {
  description = "Git credentials provisioned into 'netic-gitops-system' namespace. Expects keys 'netic' (username/password) and 'kubernetes-config' (identity)."
  type = map(object({
    username = optional(string, "")
    password = optional(string, "")
    identity = optional(string, "")
  }))
}
