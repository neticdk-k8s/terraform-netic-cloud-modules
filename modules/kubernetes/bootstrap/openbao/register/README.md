# OpenBao — register (single apply)

Registers a cluster in **its own, in-cluster OpenBao** so external-secrets can read from it. Runs `bao` inside the OpenBao pod via `kubectl exec` — no `vault` provider, so seal, init and registration fit in **one apply**, without port-forward, ingress or DNS.

```
seal/<cloud>/ → openbao-seal Secret → OpenBao starts & auto-unseals
init/         → bao operator init  → root token + recovery keys
register/     → bao via kubectl exec → KV, auth, policy, role, seed secrets
```

## What it creates

| In OpenBao | Value |
|---|---|
| KV v2 mount | `<cluster_provider>` |
| Kubernetes auth | `<cluster_provider>/k8s/<cluster_name>`, in-cluster (`kubernetes.default.svc`) |
| Policy | `<auth>/external-secrets` — read `k8s/<cluster_name>/<sa namespace>/*` |
| Role | `external-secrets`, SA `external-secrets` in any namespace |
| Seed secrets | `seed_secrets`, only if missing |

In the cluster: ClusterRoleBinding `openbao-auth-delegator` (OpenBao's SA → `system:auth-delegator`) for TokenReview.

Idempotent: existing mounts and secrets are kept. Re-runs when the script, inputs or cluster (API server) change.

## Usage

```hcl
module "openbao_register" {
  source     = ".../bootstrap/openbao/register"
  kubeconfig = local.kubeconfig
  root_token = module.openbao_init.root_token

  cluster_provider = "netic-platform-ovh"       # must match SecretStore path
  cluster_name     = "netic-k8s-services-test"  # and mountPath

  seed_secrets = {
    "netic-keycloak-system/keycloak" = {
      static    = { db_username = "keycloak", keycloak_username = "netic_admin" }
      generated = ["db_password", "keycloak_password"]
    }
  }
}
```

Generated values are 32 alphanumeric chars, created at apply time and passed to the pod over stdin — they are never in Terraform state. Static values are.

## Requirements

`kubectl` and `jq` on the machine running Terraform.

## register/ or the parent module?

| | `register/` | `../` (parent) |
|---|---|---|
| OpenBao | in the same cluster | central / reached over the network |
| Applies | one | two (vault provider needs the token at plan time) |
| Tenant groups (OIDC/JWT), operator/provider groups, PKI | no | yes |
