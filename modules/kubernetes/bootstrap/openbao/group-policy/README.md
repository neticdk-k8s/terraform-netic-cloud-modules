# OpenBao — group + policy

Internal submodule used by [`bootstrap/openbao`](../README.md). Creates a
single OpenBao ACL policy and an external identity group aliased to an
upstream IdP group. Not meant to be called directly — it exists so the parent
module can spin up one of these per tenant namespace, per operator group, and
per provider group without repeating the same five resources each time.

Provider-agnostic: the IdP group id is passed in via `alias_id`. This module
never creates the IdP group itself — see the parent module's README for why.

## What it creates

- a `vault_policy` from `policy_name` / `policy_content`
- an external `vault_identity_group`, aliased to `alias_id` via either:
  - the OIDC mount (`alias_mount_accessor`) — interactive users, or
  - the JWT mount (`alias_jwt_mount_accessor`) — automation, in which case the
    group is named `<group_name>-jwt`

Exactly one of `alias_mount_accessor` / `alias_jwt_mount_accessor` is used per
call; the parent module decides which by which one it passes.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `policy_name` | `string` | — | Name of the OpenBao policy to create |
| `policy_content` | `string` | — | ACL policy (HCL) |
| `group_name` | `string` | — | Name of the external identity group |
| `alias_id` | `string` | — | IdP group id (Entra object_id, Keycloak group id, ...) put in the token's groups claim |
| `alias_mount_accessor` | `string` | `null` | OIDC auth mount accessor — used when `alias_jwt_mount_accessor` is null |
| `alias_jwt_mount_accessor` | `string` | `null` | JWT auth mount accessor — when set, creates a `-jwt` group instead |
| `additional_operator_group_policies` | `list(string)` | `[]` | Extra policy names to attach besides the one this module creates |

## Outputs

| Name | Description |
|------|-------------|
| `policy_name` | Name of the created policy |
| `group_id` | Canonical id of the created external identity group |
