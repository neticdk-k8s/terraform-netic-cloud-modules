#!/usr/bin/env bash
# Registers the cluster in OpenBao so external-secrets can read from it:
#   KV v2 mount, Kubernetes auth (in-cluster), external-secrets policy + role,
#   and seed secrets that do not exist yet.
#
# Runs `bao` inside the OpenBao pod via kubectl exec — no port-forward, ingress
# or DNS. Idempotent: existing mounts and secrets are kept as they are.
#
# Env (set by main.tf): KUBECONFIG_RAW BAO_TOKEN BAO_ADDR NAMESPACE POD CONTAINER
#                       PROVIDER CLUSTER SEED_JSON
set -euo pipefail

KUBECONFIG="$(mktemp)"
trap 'rm -f "$KUBECONFIG"' EXIT
printf '%s' "$KUBECONFIG_RAW" >"$KUBECONFIG"
export KUBECONFIG

# Runs the shell script on stdin inside the pod. The token goes over stdin too,
# so it never shows up in a process list.
in_pod() {
  { printf '%s\n' "$BAO_TOKEN"; cat; } |
    kubectl exec -i -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- \
      sh -c "read -r BAO_TOKEN; export BAO_TOKEN BAO_ADDR='$BAO_ADDR'; exec sh -s"
}

# Single-quotes a value for the pod's POSIX sh
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

gen() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true; }

# Kubernetes auth runs in-cluster: OpenBao validates ServiceAccount tokens with
# its own SA, which therefore needs system:auth-delegator.
SA="$(kubectl -n "$NAMESPACE" get pod "$POD" -o jsonpath='{.spec.serviceAccountName}')"
kubectl apply -f - >/dev/null <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: openbao-auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: ${SA}
    namespace: ${NAMESPACE}
YAML

echo "==> Registering $CLUSTER in OpenBao"
in_pod <<SH
set -eu
AUTH=$(q "$PROVIDER/k8s/$CLUSTER")
MOUNT=$(q "$PROVIDER")

if bao read "sys/mounts/\$MOUNT" >/dev/null 2>&1; then echo "  ✔ kv mount \$MOUNT"
else bao secrets enable -path="\$MOUNT" -version=2 kv >/dev/null; echo "  + kv mount \$MOUNT"; fi

if bao read "sys/auth/\$AUTH" >/dev/null 2>&1; then echo "  ✔ auth \$AUTH"
else bao auth enable -path="\$AUTH" kubernetes >/dev/null; echo "  + auth \$AUTH"; fi

# Always rewritten: cheap, and replaces config left by an older setup
bao write "auth/\$AUTH/config" kubernetes_host="https://kubernetes.default.svc" >/dev/null
echo "  ✔ auth config (in-cluster)"

# Each namespace may read only its own subtree: k8s/<cluster>/<namespace>/*
ACCESSOR="\$(bao read -field=accessor "sys/auth/\$AUTH")"
POLICY="\$AUTH/external-secrets"
printf '%s\n' \
  "path \"\$MOUNT/data/k8s/$CLUSTER/{{identity.entity.aliases.\$ACCESSOR.metadata.service_account_namespace}}/*\" {" \
  '  capabilities = ["read", "list"]' \
  '}' | bao policy write "\$POLICY" - >/dev/null
echo "  ✔ policy \$POLICY"

bao write "auth/\$AUTH/role/external-secrets" \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces='*' \
  token_ttl=3600 token_policies="\$POLICY" >/dev/null
echo "  ✔ role external-secrets"
SH

# Seed secrets: one exec per secret, values built here (generated ones never
# leave this process except via stdin to the pod).
for path in $(jq -r 'keys[]' <<<"$SEED_JSON"); do
  args=""
  while IFS=$'\t' read -r k v; do
    [ -n "$k" ] && args="$args $(q "$k=$v")"
  done < <(jq -r --arg p "$path" '.[$p].static // {} | to_entries[] | [.key, .value] | @tsv' <<<"$SEED_JSON")
  for k in $(jq -r --arg p "$path" '.[$p].generated // [] | .[]' <<<"$SEED_JSON"); do
    args="$args $(q "$k=$(gen)")"
  done

  in_pod <<SH
set -eu
P=$(q "k8s/$CLUSTER/$path")
if bao kv get -mount=$(q "$PROVIDER") "\$P" >/dev/null 2>&1; then echo "  ✔ secret \$P (kept)"
else bao kv put -mount=$(q "$PROVIDER") "\$P" $args >/dev/null; echo "  + secret \$P"; fi
SH
done

echo "==> OpenBao registration done"
