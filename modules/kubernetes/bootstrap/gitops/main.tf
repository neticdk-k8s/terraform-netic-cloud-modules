locals {
  git_auth_manifests = {
    for key, auth in var.git_auth : key => <<-YAML
      ---
      apiVersion: v1
      kind: Namespace
      metadata:
        labels:
          name: netic-gitops-system
        name: netic-gitops-system
      ---
      apiVersion: v1
      kind: Secret
      metadata:
        name: ${key}-git-auth
        namespace: netic-gitops-system
      type: Opaque
      data:
      %{for field, value in auth~}
        ${field}: ${base64encode(value)}
      %{endfor~}
    YAML
  }
}

# Kubeconfig sendes via env var (KUBECONFIG_RAW) og skrives til en unik
# mktemp-fil pr. provisioner-kørsel — parallelle modul-instanser (fx service-
# og utility-cluster i samme root) kan derfor aldrig overskrive hinandens
# kubeconfig, og der efterlades ingen cluster-credentials på disk.

# Wait until the node pool is actually ready before trying to apply anything.
# Uses kubectl (works for any provider) instead of `az aks command invoke`.
resource "null_resource" "wait_for_workers" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      printf '%s' "$KUBECONFIG_RAW" > "$KUBECONFIG"
      export KUBECONFIG

      echo "--- Cluster API reachability ---"
      kubectl cluster-info 2>&1 | head -5 || echo "WARN: kubectl cluster-info failed (API not reachable?)"

      # The node pool resource returns before nodes have registered (OVH still
      # provisions the VMs), so poll for at least one Node object first —
      # `kubectl wait --all` errors with "no matching resources found" on an
      # empty set instead of waiting.
      echo "Waiting for at least one node to register (up to 10m)..."
      node_count=0
      for i in $(seq 1 60); do
        node_count="$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')"
        if [ "$node_count" -gt 0 ]; then
          echo "Found $node_count node(s) after $((i * 10))s"
          break
        fi
        sleep 10
      done

      if [ "$node_count" -eq 0 ]; then
        echo "ERROR: no nodes registered after 10m — dumping diagnostics"
        echo "--- nodes ---";            kubectl get nodes -o wide 2>&1 || true
        echo "--- kube-system pods ---"; kubectl get pods -n kube-system -o wide 2>&1 || true
        echo "--- events (all ns, last 40) ---"
        kubectl get events -A --sort-by=.lastTimestamp 2>&1 | tail -40 || true
        echo
        echo "The API is reachable but no worker joined. OVH provisions the VMs but"
        echo "they never register — almost always missing internet EGRESS (SNAT"
        echo "gateway on the nodes' subnet) or DHCP. Check the OVH portal: node pool"
        echo "status, and that the gateway is Active and attached to the subnet."
        exit 1
      fi

      kubectl wait --for=condition=Ready nodes --all --timeout=600s
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
    }
  }
}

# Create the netic-gitops-system namespace + git-auth secrets on the cluster.
# Piped via stdin to avoid leaving secret YAML files on disk after apply.
resource "null_resource" "netic_git_auth" {
  for_each = var.git_auth

  triggers = {
    manifest_hash = sha256(local.git_auth_manifests[each.key])
  }

  # Server-side apply: atomisk upsert, så parallelle instanser ikke racer
  # om at oprette den fælles namespace (GET→CREATE giver AlreadyExists).
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      printf '%s' "$KUBECONFIG_RAW" > "$KUBECONFIG"
      export KUBECONFIG
      printf '%s' "$MANIFEST" | kubectl apply --server-side --force-conflicts -f -
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      MANIFEST       = local.git_auth_manifests[each.key]
    }
  }

  depends_on = [null_resource.wait_for_workers]
}

resource "null_resource" "gitops_bootstrap" {
  # Re-run bootstrap når repo/path eller git-credentials ændres
  triggers = {
    cluster_repo     = var.cluster_repo
    bootstrap_path   = var.bootstrap_path
    gotk_repo        = var.gotk_repo
    gotk_path        = var.gotk_path
    git_ssh_port     = var.git_ssh_port
    keyscan_image    = var.keyscan_image
    git_protocol     = var.git_protocol
    git_auth_hash    = sha256(jsonencode(var.git_auth))
    git_ssh_key_hash = sha256(var.git_ssh_private_key)
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/gitops-bootstrap.sh ${var.cluster_repo} ${var.bootstrap_path} ${var.gotk_repo} ${var.gotk_path} ${var.git_ssh_port}"
    working_dir = path.cwd

    environment = {
      KUBECONFIG_RAW        = var.kubeconfig
      keyscan_image         = var.keyscan_image
      netic_username        = try(var.git_auth["netic"].username, "")
      netic_password        = try(var.git_auth["netic"].password, "")
      kubernetes_config_key = try(var.git_auth["kubernetes-config"].identity, "")
      git_protocol          = var.git_protocol
      git_ssh_private_key   = var.git_ssh_private_key
    }
  }

  depends_on = [null_resource.wait_for_workers, null_resource.netic_git_auth]
}
