variable "kubeconfig" {
  description = "Raw kubeconfig for the cluster. Uses kubectl only, so no cloud-specific CLI is required."
  type        = string
  sensitive   = true
}

variable "enabled" {
  description = <<-EOT
    Apply the compatibility settings. Only turn this on for clusters that run
    Istio with sidecars or the Istio CNI plugin — both settings cost something
    on a cluster without a service mesh. See the README.
  EOT
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the CiliumNodeConfig object."
  type        = string
  default     = "cilium-istio-compat"
}

variable "namespace" {
  description = "Namespace Cilium runs in. CiliumNodeConfig must live alongside it."
  type        = string
  default     = "kube-system"
}

variable "node_selector" {
  description = "Nodes to apply the overrides to. Empty map = all nodes, which is what a mesh-enabled cluster wants."
  type        = map(string)
  default     = {}
}

variable "settings" {
  description = <<-EOT
    Cilium options to override, as string values.

    Defaults are the documented Cilium + Istio compatibility pair:

      cni-exclusive = "false"
        Cilium otherwise rewrites the CNI config and strips Istio's plugin,
        which Istio writes straight back — a hot loop that leaves istio-cni
        permanently unready.

      bpf-lb-sock-hostns-only = "true"
        Restricts Cilium's socket load balancing to the host namespace.
        Without it, socket LB short-circuits connections before the sidecar
        proxy sees them, so mesh traffic silently bypasses Istio.
  EOT
  type        = map(string)
  default = {
    "cni-exclusive"           = "false"
    "bpf-lb-sock-hostns-only" = "true"
  }
}

variable "restart_cilium" {
  description = <<-EOT
    Roll the Cilium DaemonSet so the agents pick the overrides up. Required
    when Cilium is already running — which it is on a managed cluster, since
    the CNI comes up with the cluster.

    A rollout briefly disrupts networking on every node, so run this module
    early: before workloads and before Istio is deployed.
  EOT
  type        = bool
  default     = true
}

variable "cilium_daemonset" {
  description = "Name of the Cilium DaemonSet to roll."
  type        = string
  default     = "cilium"
}

variable "rollout_timeout" {
  description = "How long to wait for the Cilium rollout to finish, as a kubectl duration."
  type        = string
  default     = "5m"
}
