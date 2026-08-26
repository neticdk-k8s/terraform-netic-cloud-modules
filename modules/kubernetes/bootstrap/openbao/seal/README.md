# OpenBao seal — auto-unseal credentials

Creates the Secret OpenBao reads to auto-unseal against a cloud KMS, so the
server starts without anyone entering unseal keys.

```
seal/
  ovh/   — OVHcloud KMS (OKMS): mTLS or token
  azure/ — Azure Key Vault (not built yet)
```

Call the leaf module for the cloud your OpenBao runs in. A `wrapper/` is worth
adding once a second implementation exists — with one, it would only add
indirection.

## Why there is no shared abstraction yet

The seal mechanisms differ more than the cluster modules do, so a common
interface would be mostly pass-through:

| | OVH (OKMS) | Azure (Key Vault) |
|---|---|---|
| Seal type | `ovhcloud` | `azurekeyvault` |
| Auth | mTLS client cert, or bearer token | Entra ID: client credentials, or Managed / Workload Identity |
| Credential in cluster | Secret with PEMs or token | often **none** — Workload Identity needs no secret material |

Choosing mTLS on OVH does not by itself make Azure symmetric. On AKS the
idiomatic setup is Workload Identity, where there is no credential to place in a
Secret at all — so an `azure/` module may end up doing considerably less than
its OVH counterpart, or nothing beyond wiring a federated identity.

What stays consistent is the **shape**: one module per cloud, taking a
`kubeconfig` plus that cloud's KMS coordinates, producing whatever the chart
needs, and rolling the StatefulSet on change.

## Where this sits

```
apply 1   seal/<cloud>/ → openbao-seal Secret → OpenBao starts & auto-unseals
          ../init/      → bao operator init  → root token + recovery keys

apply 2   ../           → VAULT_ADDR + token → auth backend, policies, roles
```

`init/` is a module too, so the whole first apply is automated. Registration is
a separate apply because its `vault` provider needs the token at plan time.

None of these modules deploys the OpenBao server — that is GitOps/Helm's job.
