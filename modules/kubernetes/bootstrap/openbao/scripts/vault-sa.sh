#!/usr/bin/env bash
# Provider-agnostic replacement for the old `az aks command invoke` approach.
# Creates the OpenBao token-reviewer ServiceAccount on the target cluster and
# writes its token secret (ca.crt + token) as JSON to $1, for Terraform to read
# back and feed into the kubernetes auth backend config.
#
# Auth to the cluster comes purely from the kubeconfig passed in KUBECONFIG_RAW,
# so this works on AKS, OVH Managed Kubernetes, or anything else with a kubeconfig.
#
#   $1 = output path for the secret JSON

set -e

OUT="$1"

KUBECONFIG="$(mktemp)"
trap 'rm -f "$KUBECONFIG"' EXIT
printf '%s' "$KUBECONFIG_RAW" >"$KUBECONFIG"
export KUBECONFIG

kubectl apply -f - <<'EOF'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: kube-system
EOF

# The token controller populates .data.token asynchronously — poll for it.
echo "Waiting for the vault-auth token to be issued..."
for _ in $(seq 1 30); do
  if [ -n "$(kubectl get -n kube-system secret vault-auth-token -o jsonpath='{.data.token}' 2>/dev/null)" ]; then
    break
  fi
  sleep 2
done

kubectl get -n kube-system secret vault-auth-token -o json >"$OUT"
