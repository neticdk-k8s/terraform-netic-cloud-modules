# Creates the Secret holding OpenBao's OVHcloud KMS auto-unseal credentials.
#
# Runs in the same apply as ../../init, and before it: the seal Secret must exist
# before OpenBao can start, and `bao operator init` needs a started server.
#
# Registration (../..) is a separate apply. Its `vault` provider is configured at
# plan time and needs the token that init produces, so one apply cannot both
# create that precondition and consume it.
#
# Creating this Secret outside GitOps is the correct exception — OpenBao's own
# unseal credentials cannot be stored in OpenBao, and External Secrets cannot
# read them before OpenBao is up.

locals {
  # Which mode is in use is not itself a secret, even though it is derived from
  # the sensitive `auth` object — without this, every output computed from it
  # would be sensitive too.
  use_mtls = nonsensitive(var.auth.client_cert_pem != null)

  # Non-secret coordinates, consumed as env vars via extraSecretEnvironmentVars.
  base_data = {
    BAO_SEAL_TYPE        = "ovhcloud"
    OVHCLOUDKMS_ENDPOINT = var.okms.endpoint
    OVHCLOUDKMS_ID       = var.okms.kms_id
    OVHCLOUDKMS_KEY_ID   = var.okms.key_id
  }

  # OVHCLOUDKMS_CLIENT_CERT / _CLIENT_KEY take file PATHS, so the PEMs go in as
  # their own keys and are projected into the pod as files by a volume — see
  # the Helm values in the README. The paths themselves are plain literals and
  # belong in extraEnvironmentVars, not here.
  auth_data = local.use_mtls ? {
    "client_cert.pem" = var.auth.client_cert_pem
    "client_key.pem"  = var.auth.client_key_pem
    } : {
    OVHCLOUDKMS_TOKEN = var.auth.token
  }

  seal_data = merge(local.base_data, local.auth_data)

  manifest = <<-YAML
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: ${var.secret_name}
      namespace: ${var.namespace}
    type: Opaque
    data:
    %{for k, v in local.seal_data~}
      ${k}: ${base64encode(v)}
    %{endfor~}
  YAML

  # Hashing the rendered manifest gives a stable change signal. nonsensitive()
  # is safe on a digest and keeps the trigger usable in state.
  manifest_hash = nonsensitive(sha256(local.manifest))
}

# Piped via stdin (never written to disk, never passed as argv) so credentials
# do not leak into process listings or leftover files.
resource "null_resource" "seal_secret" {
  triggers = {
    manifest_hash = local.manifest_hash
    namespace     = var.namespace
    secret_name   = var.secret_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      KUBECONFIG="$(mktemp)"
      trap 'rm -f "$KUBECONFIG"' EXIT
      printf '%s' "$KUBECONFIG_RAW" > "$KUBECONFIG"
      export KUBECONFIG

      # On a freshly built cluster GitOps has usually not reconciled the
      # namespace yet, so a plain apply races Flux and fails with NotFound.
      if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
        echo "Namespace $NS not found — waiting up to $${NS_TIMEOUT}s for GitOps..."
        waited=0
        while [ "$waited" -lt "$NS_TIMEOUT" ]; do
          if kubectl get namespace "$NS" >/dev/null 2>&1; then break; fi
          sleep 5
          waited=$((waited + 5))
        done
      fi

      # Creating it is safe and breaks a real deadlock: the GitOps Kustomization
      # that would create this namespace also carries OpenBao's Certificate,
      # which cannot be validated until the namespace exists. Flux adopts the
      # namespace on its next reconcile via server-side apply.
      if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
        if [ "$CREATE_NS" = "true" ]; then
          echo "Namespace $NS still absent — creating it."
          kubectl create namespace "$NS"
        else
          echo "ERROR: namespace $NS does not exist and create_namespace is false." >&2
          exit 1
        fi
      fi

      printf '%s' "$MANIFEST" | kubectl apply --server-side --force-conflicts -f -
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      MANIFEST       = local.manifest
      NS             = var.namespace
      NS_TIMEOUT     = var.namespace_timeout_seconds
      CREATE_NS      = tostring(var.create_namespace)
    }
  }
}

# Secret-backed env vars and mounted files are only read when the container
# starts, so a changed credential does nothing until the pod is recreated.
resource "null_resource" "restart" {
  count = var.restart_statefulset ? 1 : 0

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

      # Absent on the very first apply — OpenBao may not be deployed yet, and
      # the kubelet picks the Secret up on its next retry anyway.
      if kubectl get statefulset "$STS" -n "$NS" >/dev/null 2>&1; then
        kubectl rollout restart "statefulset/$STS" -n "$NS"
      else
        echo "StatefulSet $STS not found in $NS — skipping restart."
      fi
    EOT

    environment = {
      KUBECONFIG_RAW = var.kubeconfig
      STS            = var.statefulset_name
      NS             = var.namespace
    }
  }

  depends_on = [null_resource.seal_secret]
}
