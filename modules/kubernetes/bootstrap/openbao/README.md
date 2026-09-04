# OpenBao / Vault — cluster registration & tenant policies

> **Three entry points, two applies.** This folder is the *registration* module,
> which needs a running, initialised OpenBao. Start with [`seal/`](./seal), then
> [`init/`](./init) — both belong to the same first apply. None of the three
> deploys the OpenBao server itself; that is GitOps/Helm's job.
>
> ```
> apply 1   seal/<cloud>/ → openbao-seal Secret → OpenBao starts & auto-unseals
>           init/         → bao operator init  → root token + recovery keys
>                                              → store them in a secret store
>
> apply 2   ./            → VAULT_ADDR + token → auth backend, policies, roles
> ```
>
> Registration must be a separate apply: its `vault` provider is configured at
> **plan** time and needs the token that `init/` produces. No `depends_on`
> bridges provider configuration. With the token persisted to a secret store,
> there is still no manual step between the two applies.

Registers a running Kubernetes cluster in **OpenBao/HashiCorp Vault** and lays
down the standard Netic policy/identity layout for it:

- a KV **v2** engine at `cluster_provider` (`create_kv_mount`, default `true` —
  set `false` against a central OpenBao where it's managed elsewhere; guarded by
  `prevent_destroy` unless `protect_kv_mount = false`),
- a `kubernetes` auth backend at `<cluster_provider>/k8s/<cluster_name>`, wired to
  a `vault-auth` token-reviewer ServiceAccount it creates on the cluster,
- the `external-secrets` role + policy,
- optional PKI `cert-manager` role/policy,
- per-namespace tenant groups (interactive OIDC and automation JWT),
- optional `operator_user` / `provider_user` groups.

This is a **bootstrap-style, provider-agnostic module** — exactly like
[`bootstrap/gitops`](../gitops). It talks only to the OpenBao API and to the
cluster via a `kubeconfig`, so the same code runs whether the cluster is on
**Azure (AKS)** or **OVHcloud**. There is deliberately **no `azurerm`/`azuread`**
dependency:

| Old (Azure-only) | Now (generic) |
|---|---|
| `data.azurerm_kubernetes_cluster` for host/region | `kubernetes_host` + `cluster_name` inputs |
| `az aks command invoke` (`scripts/vault-sa.sh`) | `kubectl` against the passed `kubeconfig` |
| `azuread_group` create/lookup for group aliases | IdP group ids passed in via `alias_id` |

## What it does NOT do

It does not create IdP groups. The alias id for every group (`namespaces`,
`namespaces_automated`, operator, provider) is an **input** — feed in the object
id / UUID that your OIDC/JWT provider (Entra ID, Keycloak, ...) puts in the
token's `groups` claim. If you need Entra groups auto-created, keep that in your
Azure/management module and pass the resulting object ids in here.

## Usage

```hcl
module "openbao" {
  source = "../../modules/kubernetes/bootstrap/openbao"

  cluster_name     = local.cluster_name          # your composed identity
  cluster_provider = "ovh"                        # KV mount / path segment
  kubernetes_host  = module.kubernetes.cluster_endpoint
  kubeconfig       = module.kubernetes.kubeconfig

  enable_pki_engine = true
}
```

That minimal call registers the cluster and makes the `external-secrets`
SecretStores go Ready — no groups, no OIDC/JWT mounts required.

### Adding user / automation groups (optional)

Only when you actually manage interactive or automation groups do you need the
auth-mount accessors. Declare the data sources **in your root module** (they
only resolve once the mounts exist in OpenBao — OIDC/JWT is typically
Keycloak- or Entra-backed):

```hcl
data "vault_auth_backend" "oidc" { path = "oidc" }   # interactive users
data "vault_auth_backend" "jwt"  { path = "jwt" }    # automation (CI/workload)

module "openbao" {
  # ...the cluster inputs above...

  alias_mount_accessor     = data.vault_auth_backend.oidc.accessor
  alias_jwt_mount_accessor = data.vault_auth_backend.jwt.accessor

  namespaces           = { team-a = "3f7c...oidc-group-id" }  # interactive
  namespaces_automated = { team-a = "9a12...jwt-group-id" }   # automation
  operator_group_id    = "aaaa-....-operators"
  provider_group_id    = "bbbb-....-providers"
}
```

Leave `alias_jwt_mount_accessor` unset (and `namespaces_automated` empty) if you
have no automation identities — do **not** reference a `jwt` data source you did
not declare. The module never looks up the `oidc` mount unless you pass
`namespaces` / `operator_group_id` / `provider_group_id`.

The `vault` provider must be configured by the caller. `kubectl` must be on
`PATH` where Terraform runs (same requirement as `bootstrap/gitops`).

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | — | Final unique cluster identity string |
| `cluster_provider` | `string` | — | KV mount / path segment (e.g. `"azure"`, `"ovh"`) |
| `create_kv_mount` | `bool` | `true` | Mount a KV **v2** engine at `cluster_provider`. Set `false` against a central OpenBao where it already exists |
| `protect_kv_mount` | `bool` | `true` | Guard the mount with `prevent_destroy`. Set `false` for one-OpenBao-per-cluster, where the mount dies with the cluster. Flipping it relocates the resource — move it with `tofu state mv`, do not apply the change |
| `kubernetes_host` | `string` | — | Kube API URL (cluster module's `cluster_endpoint`) |
| `kubeconfig` | `string` (sensitive) | — | Raw kubeconfig, used to create the token-reviewer SA |
| `alias_mount_accessor` | `string` | `null` → accessor of mount `oidc` | OIDC auth mount accessor |
| `alias_jwt_mount_accessor` | `string` | `null` | JWT auth mount accessor (automation groups) |
| `namespaces` | `map(string)` | `{}` | namespace → IdP group id (OIDC) |
| `namespaces_automated` | `map(string)` | `{}` | namespace → IdP group id (JWT) |
| `operator_group_id` | `string` | `null` | IdP group id for `operator_user` (null disables) |
| `provider_group_id` | `string` | `null` | IdP group id for `provider_user` (null disables) |
| `additional_operator_group_policies` | `list(string)` | `[]` | Extra policies on the operator group |
| `external_secrets_policy_additional` | `list(string)` | `[]` | Extra policies on the external-secrets role |
| `enable_pki_engine` | `bool` | `false` | Create PKI `cert-manager` role/policy (needs a `pki` mount) |

## Outputs

| Name | Description |
|------|-------------|
| `kubernetes_auth_path` | Path of the mounted Kubernetes auth backend |
| `kubernetes_auth_accessor` | Accessor of that auth backend |
| `cluster_name` | The cluster identity used |
| `kv_mount_path` | Path of the KV v2 engine. Must match `spec.provider.vault.path` in the SecretStores |
| `kv_mount_created` | Whether this module mounted the engine, or expects it to exist |
| `secret_path_prefix` | Where secrets belong: `<mount>/k8s/<cluster>/<namespace>/<app>` |

## Notes

- **Token secret on disk** — the token-reviewer SA's secret (ca.crt + token) is
  written to `vault-sa-secret-<cluster_name>.json` in the root working dir so
  Terraform can read it back into the auth config. The filename is namespaced by
  cluster so two clusters in one root don't collide. Add it to `.gitignore`: it
  is a privileged credential and it stays on disk after apply.

- **Rebuilding a cluster reuses the same identity.** `cluster_name` is the same
  string before and after a destroy/redeploy, so it cannot on its own tell the
  module that the token reviewer must be recreated. `kubernetes_host` is part of
  the trigger for exactly this reason — the API hostname is unique per cluster.

  Without it the failure is hard to spot: the auth backend exists,
  `kubernetes_host` reads correctly, certificates are green — but every login
  fails, because OpenBao validates tokens against the new cluster using the old
  cluster's reviewer credentials. The symptom surfaces three layers away, as
  pods stuck in `CreateContainerConfigError`.

  On an ephemeral CI runner the stale file is absent anyway, which changes the
  `fileexists` trigger and re-runs the script. The host trigger is what protects
  local runs and any workflow that restores the file.

- **A missing KV mount looks like a permissions problem but isn't.** The
  policies grant access under `<cluster_provider>/data/...`, which only exists
  once a KV v2 engine is mounted there. Without it, auth succeeds, the
  SecretStore reports "store validated", and every read fails with
  `Secret does not exist`. That is what `create_kv_mount` is for.
- **Removed features vs. the old azure module** — `namespaces_create`,
  `namespaces_automated_create` and `group_create` (which auto-created Entra
  groups) are intentionally gone. Pre-create the groups upstream and pass ids in.
