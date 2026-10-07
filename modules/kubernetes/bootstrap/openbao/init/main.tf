# Runs `bao operator init` once, turning the last manual step of the OpenBao
# bootstrap into a resource.
#
# Where this sits:
#   seal/<cloud>/ → auto-unseal credentials → OpenBao starts and unseals
#   THIS MODULE   → bao operator init       → root token + recovery keys
#   ../           → registration            → auth backend, policies, roles
#
# The registration module cannot live in the same apply as this one: its `vault`
# provider needs an address and token at plan time, and the token is what this
# module produces. Two applies, but no manual step between them.

locals {
  state_file = coalesce(
    var.state_file,
    "${path.cwd}/openbao-init-${var.namespace}.json"
  )

  bao_addr = "https://${var.service_name}.${var.namespace}.svc:${var.api_port}"
}

resource "null_resource" "init" {
  # Keyed to the cluster identity, not to the credentials: init must run once
  # per OpenBao instance. The script re-checks the server's own state anyway, so
  # a spurious trigger is harmless.
  triggers = {
    namespace    = var.namespace
    service_name = var.service_name
  }

  lifecycle {
    precondition {
      condition     = var.recovery_threshold <= var.recovery_shares
      error_message = "recovery_threshold (${var.recovery_threshold}) cannot exceed recovery_shares (${var.recovery_shares}) — the keys would be unusable."
    }
  }

  provisioner "local-exec" {
    # Both paths are quoted: a working directory containing a space would
    # otherwise be split into two arguments, and the script would write its
    # output to a truncated path that no data source can find again.
    command     = "'${path.module}/scripts/bao-init.sh' '${local.state_file}'"
    working_dir = path.cwd

    environment = {
      KUBECONFIG_RAW     = var.kubeconfig
      NAMESPACE          = var.namespace
      POD                = var.pod_name
      CONTAINER          = var.container_name
      BAO_ADDR           = local.bao_addr
      BAO_CACERT         = var.ca_cert_path
      RECOVERY_SHARES    = var.recovery_shares
      RECOVERY_THRESHOLD = var.recovery_threshold
      API_TIMEOUT        = var.api_timeout_seconds
    }
  }
}

data "local_sensitive_file" "init" {
  filename   = local.state_file
  depends_on = [null_resource.init]
}

locals {
  # try() keeps `terraform plan` working before the file exists.
  init = try(jsondecode(data.local_sensitive_file.init.content), {})

  # OpenBao emits recovery_keys_b64 / recovery_keys_hex. HashiCorp Vault uses
  # recovery_keys_base64, so accept either — reading the wrong key would yield
  # an empty list and silently "back up" nothing.
  recovery_keys = try(
    local.init.recovery_keys_b64,
    local.init.recovery_keys_base64,
    local.init.recovery_keys,
    [],
  )

  root_token = try(local.init.root_token, "")
}
