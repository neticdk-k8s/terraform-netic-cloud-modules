# OpenBao — operator init

Runs `bao operator init` once, so the last manual step of the OpenBao bootstrap
becomes a resource. Outputs the root token and recovery keys for the caller to
store wherever it wants — this module deliberately does not choose a secret
store, so the same module works on OVH, Azure, or anywhere else.

## Usage

```hcl
module "openbao_init" {
  source     = ".../bootstrap/openbao/init"
  kubeconfig = module.service_cluster.kubeconfig

  depends_on = [module.openbao_seal] # unseal must be configured first
}

# Persist the credentials — OVH example (version.data is write-only)
resource "ovh_okms_secret" "openbao_root" {
  okms_id = data.ovh_okms_resource.this.id
  path    = "openbao/${local.cluster_name}/root"

  version = {
    data = jsonencode({
      root_token    = module.openbao_init.root_token
      recovery_keys = module.openbao_init.recovery_keys
    })
  }
}
```

## Next step

- **In-cluster OpenBao:** [`../register`](../register) in the **same** apply,
  with `root_token = module.openbao_init.root_token`.
- **Central OpenBao:** the parent module in a **second** apply — its `vault`
  provider needs the token at plan time, so read it back from the secret store:

```hcl
data "ovh_okms_secret" "openbao_root" {
  okms_id      = data.ovh_okms_resource.this.id
  path         = "openbao/${local.cluster_name}/root"
  include_data = true
}

provider "vault" {
  address = "https://vault.example.netic.dk"
  token   = jsondecode(data.ovh_okms_secret.openbao_root.data).root_token
}
```

## Idempotency

The **server** is the source of truth, not the state file. The script asks
`bao status` first and exits cleanly if OpenBao reports `initialized: true`, so
re-applies are safe and a redeploy is never blocked by a stale file.

One case fails loudly on purpose: OpenBao already initialised but the state file
missing or empty. The root token and recovery keys are shown exactly once and
cannot be recovered, so silently continuing would leave you locked out. Supply
the stored values, or wipe the storage and let it initialise from scratch.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kubeconfig` | `string` (sensitive) | — | Raw kubeconfig for the cluster |
| `namespace` | `string` | `"netic-vault-system"` | Namespace OpenBao runs in |
| `service_name` | `string` | `"openbao"` | Service name, used to build the API address |
| `pod_name` | `string` | `"openbao-0"` | Pod to exec into |
| `container_name` | `string` | `"openbao"` | Container running the bao binary |
| `api_port` | `number` | `8200` | API port |
| `ca_cert_path` | `string` | `/openbao/userconfig/openbao-server-tls/ca.crt` | `BAO_CACERT` inside the container |
| `api_timeout_seconds` | `number` | `600` | How long to wait for the OpenBao API. On a fresh cluster GitOps still has to reconcile the HelmRelease and pull the image, so the pod does not exist for the first minutes |
| `recovery_shares` | `number` | `5` | Recovery key shares to generate |
| `recovery_threshold` | `number` | `3` | Shares needed to act; must not exceed shares |
| `state_file` | `string` | `openbao-init-<namespace>.json` in cwd | Where the init JSON is written |

## Outputs

| Name | Description |
|------|-------------|
| `root_token` | Initial root token *(sensitive)* |
| `recovery_keys` | Recovery key shares, base64 *(sensitive)* |
| `api_addr` | In-cluster API address |
| `state_file` | Path the init JSON was written to |

## Notes

- **The state file holds the cluster's most privileged credentials.** It is
  written with `umask 077`, but it is still plaintext on disk. Store the outputs
  in a real secret store and delete it. The values also enter Terraform state,
  so treat state as a secret too.
- **Root tokens cannot be scoped.** Use the root token once to create a
  policy-limited token or AppRole for automation, then revoke root.
- **Recovery keys are not unseal keys.** With auto-unseal the KMS holds the
  seal; the recovery keys exist for the case where the KMS key is lost. Losing
  both means losing the data.
- **The API address uses the Service DNS name.** The server certificate carries
  DNS SANs only (`openbao`, `openbao.<ns>.svc`, …), so `127.0.0.1` fails
  certificate validation.
- `kubectl` must be on `PATH` (same requirement as `bootstrap/gitops`).
