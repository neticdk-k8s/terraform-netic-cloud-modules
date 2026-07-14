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

variable "git_protocol" {
  type        = string
  description = <<-EOT
    Protocol the bootstrap script uses to clone gotk_repo and cluster_repo:
      - "https" (default): injects url-encoded username/token from git_auth["netic"].
        Pass HTTPS-style repos, e.g. "git.netic.dk/scm/pd/gotk-bootstrap-k8s.git".
      - "ssh": authenticates with git_ssh_private_key. Pass SSH-style repos, e.g.
        "ssh://git@git.netic.dk:7999/pd/gotk-bootstrap-k8s.git".
    Only affects the script's own clones — Flux's in-cluster git access still uses
    the SSH deploy key in the kubernetes-config-git-auth secret.
  EOT
  default     = "https"

  validation {
    condition     = contains(["https", "ssh"], var.git_protocol)
    error_message = "git_protocol must be \"https\" or \"ssh\"."
  }
}

variable "git_ssh_private_key" {
  type        = string
  sensitive   = true
  description = "Private SSH key (OpenSSH/PEM) used to clone when git_protocol = \"ssh\". Required in that case."
  default     = ""
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

variable "bootstrap_token" {
  type        = string
  default     = ""
  description = "Stabilt token der er den ENESTE trigger for bootstrap. Send fx en random_uuid.result ind: så kører bootstrap kun én gang, og ændringer i repo/path/protokol/credentials udløser IKKE re-bootstrap. Regenerér tokenet for bevidst at tvinge et re-bootstrap."
}
