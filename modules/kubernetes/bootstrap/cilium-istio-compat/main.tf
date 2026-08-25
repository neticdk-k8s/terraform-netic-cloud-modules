# Makes Cilium and Istio coexist, via a CiliumNodeConfig override.
#
# Why an override object and not the cilium-config ConfigMap: on OVHcloud
# Managed Kubernetes, Cilium is installed by OVH's own ArgoCD. Editing
# cilium-config works for a few minutes and is then reconciled back.
# CiliumNodeConfig is a separate object that ArgoCD does not manage, so the
# override survives — and cilium-config keeps reporting the original values.
#
# Run this BEFORE Istio is deployed. Applied first, the CNI conflict never
# happens; applied afterwards you also have to restart Cilium while workloads
# are already running.

locals {
  # yamlencode rather than a heredoc: template directives inside an indented
  # heredoc break the indentation stripping, and silently mis-indented YAML is
  # exactly the kind of bug that only shows up against a live API server.
  header = <<-EOT
    # Managed by Terraform (bootstrap/cilium-istio-compat).
    #
    # NOTE: the cilium-config ConfigMap still shows the ORIGINAL values —
    # cni-exclusive=true in particular. That is expected: this object overrides
    # them at the agent level. Do not "fix" the ConfigMap; OVH's ArgoCD owns it
    # and will revert any edit.
  EOT

  body = yamlencode({
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNodeConfig"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      # An empty selector means "every node", which is what a mesh-enabled
      # cluster wants. Cilium rejects an empty matchLabels, so omit it entirely.
      nodeSelector = length(var.node_selector) == 0 ? {} : { matchLabels = var.node_selector }
      defaults     = var.settings
    }
  })

  manifest      = "${local.header}${local.body}"
  manifest_hash = sha256(local.manifest)
}

resource "null_resource" "cilium_node_config" {
  count = var.enabled ? 1 : 0

  triggers = {
    manifest_hash = local.manifest_hash
    name          = var.name
    namespace     = var.namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      printf '%s' "$KUBECONFIG_RAW" > "$KUBECONFIG"
      export KUBECONFIG

      # The CRD ships with Cilium, so on a brand new cluster it may not be
      # registered the instant the API server accepts connections.
      echo "Waiting for the CiliumNodeConfig CRD (up to 120s)..."
      for _ in $(seq 1 24); do
        if kubectl get crd ciliumnodeconfigs.cilium.io >/dev/null 2>&1; then break; fi
        sleep 5
      done

      if ! kubectl get crd ciliumnodeconfigs.cilium.io >/dev/null 2>&1; then
        echo "ERROR: CiliumNodeConfig CRD not found. Is Cilium the CNI on this cluster?" >&2
        exit 1
      fi

      printf '%s' "$MANIFEST" | kubectl apply --server-side --force-conflicts -f -
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      MANIFEST       = local.manifest
    }
  }
}

# Cilium reads these options at agent start, so a running DaemonSet keeps the
# old behaviour until it is rolled.
resource "null_resource" "restart_cilium" {
  count = var.enabled && var.restart_cilium ? 1 : 0

  triggers = {
    manifest_hash = local.manifest_hash
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      printf '%s' "$KUBECONFIG_RAW" > "$KUBECONFIG"
      export KUBECONFIG

      echo "Rolling DaemonSet/$DS in $NS so the agents pick up the overrides..."
      kubectl rollout restart "daemonset/$DS" -n "$NS"
      kubectl rollout status  "daemonset/$DS" -n "$NS" --timeout="$TIMEOUT"
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      DS             = var.cilium_daemonset
      NS             = var.namespace
      TIMEOUT        = var.rollout_timeout
    }
  }

  depends_on = [null_resource.cilium_node_config]
}
