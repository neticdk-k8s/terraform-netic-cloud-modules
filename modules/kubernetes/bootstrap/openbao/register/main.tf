# Registers a cluster in its own, in-cluster OpenBao — single apply, no vault
# provider: everything runs as `bao` via kubectl exec (see scripts/register.sh).
#
# Use the parent module (../) instead for a central OpenBao reached over the
# network, or when tenant groups / PKI are needed.

locals {
  # Re-register when the cluster is rebuilt (new API server)
  kube_server = yamldecode(var.kubeconfig).clusters[0].cluster.server
}

resource "null_resource" "register" {
  triggers = {
    script       = filesha256("${path.module}/scripts/register.sh")
    provider     = var.cluster_provider
    cluster      = var.cluster_name
    seed_secrets = sha256(jsonencode(var.seed_secrets))
    kube_server  = nonsensitive(sha256(local.kube_server))
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/register.sh"

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      BAO_TOKEN      = var.root_token
      BAO_ADDR       = "https://${var.service_name}.${var.namespace}.svc:${var.api_port}"
      NAMESPACE      = var.namespace
      POD            = var.pod_name
      CONTAINER      = var.container_name
      PROVIDER       = var.cluster_provider
      CLUSTER        = var.cluster_name
      SEED_JSON      = jsonencode(var.seed_secrets)
    }
  }
}
