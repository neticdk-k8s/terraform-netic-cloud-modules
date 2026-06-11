terraform {
  required_version = ">= 1.3"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

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

# Write kubeconfig to a temp file so kubectl can use it directly.
# Marked sensitive so Terraform never prints the content in logs.
resource "local_sensitive_file" "kubeconfig" {
  content         = var.kubeconfig
  filename        = "${path.cwd}/.kubeconfig-bootstrap"
  file_permission = "0600"
}

# Wait until the node pool is actually ready before trying to apply anything.
# Uses kubectl (works for any provider) instead of `az aks command invoke`.
resource "null_resource" "wait_for_workers" {
  provisioner "local-exec" {
    command = <<-EOT
      sleep 60
      kubectl --kubeconfig=${local_sensitive_file.kubeconfig.filename} \
        wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  }

  depends_on = [local_sensitive_file.kubeconfig]
}

# Create the netic-gitops-system namespace + git-auth secrets on the cluster.
# Piped via stdin to avoid leaving secret YAML files on disk after apply.
resource "null_resource" "netic_git_auth" {
  for_each = var.git_auth

  triggers = {
    manifest_hash = sha256(local.git_auth_manifests[each.key])
  }

  provisioner "local-exec" {
    command = "printf '%s' \"$MANIFEST\" | kubectl --kubeconfig=${local_sensitive_file.kubeconfig.filename} apply -f -"
    environment = {
      MANIFEST = local.git_auth_manifests[each.key]
    }
  }

  depends_on = [null_resource.wait_for_workers]
}

resource "null_resource" "gitops_bootstrap" {
  # Re-run bootstrap når repo/path eller git-credentials ændres
  triggers = {
    cluster_repo   = var.cluster_repo
    bootstrap_path = var.bootstrap_path
    gotk_repo      = var.gotk_repo
    gotk_path      = var.gotk_path
    git_ssh_port   = var.git_ssh_port
    git_auth_hash  = sha256(jsonencode(var.git_auth))
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/gitops-bootstrap.sh ${var.cluster_repo} ${var.bootstrap_path} ${var.gotk_repo} ${var.gotk_path} ${var.git_ssh_port}"
    working_dir = path.cwd

    environment = {
      KUBECONFIG_RAW        = var.kubeconfig
      netic_username        = var.git_auth["netic"].username
      netic_password        = var.git_auth["netic"].password
      kubernetes_config_key = try(var.git_auth["kubernetes-config"].identity, "")
    }
  }

  depends_on = [null_resource.wait_for_workers, null_resource.netic_git_auth]
}
