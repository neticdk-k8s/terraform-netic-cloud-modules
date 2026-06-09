#!/usr/bin/env bash

set -eo pipefail

# Unik suffix per kørsel så parallelle kald ikke kolliderer på temp-filer
_run_id="$$-$(date +%s)"

export KUBECONFIG="$(pwd)/kvm-kubeconfig-${_run_id}.tmp"
echo "$KUBECONFIG_RAW" > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

checkout_gotk="$(pwd)/gotk-bootstrap-k8s-${_run_id}"
checkout_config="$(pwd)/kubernetes-config-${_run_id}"
known_hosts_tmp="/tmp/known_hosts-${_run_id}"
keyscan_pod="ssh-keyscan-${_run_id}"

trap 'rm -f "$KUBECONFIG" "$known_hosts_tmp"; rm -rf "$checkout_gotk" "$checkout_config"; kubectl delete pod "$keyscan_pod" --ignore-not-found=true 2>/dev/null || true' EXIT

gitops_username=$(echo "${netic_username}" | jq -Rr @uri)
gitops_token=$(echo "${netic_password}" | jq -Rr @uri)

# --- Apply Flux / gotk components ---
git clone --depth 1 "https://${gitops_username}:${gitops_token}@git.netic.dk/scm/pd/gotk-bootstrap-k8s.git" "${checkout_gotk}"
pushd "${checkout_gotk}/gotk"
{
  echo "=== GOTK DEBUG $(date) ==="
  echo "perl test: $(echo '${foo:=bar}' | perl -pe 's/\$\{(\w+)(?::=([^}]*))?\}/$ENV{$1} \/\/ $2 \/\/ ""/ge')"
  perl -pe 's/\$\{(\w+)(?::=([^}]*))?\}/$ENV{$1} \/\/ $2 \/\/ ""/ge' gotk-components.yaml > /tmp/gotk-substituted.yaml
  echo "memory linje: $(grep 'source_controller_mem\|memory:' /tmp/gotk-substituted.yaml | head -3)"
} > /tmp/gotk-debug.log 2>&1
kubectl apply --server-side --force-conflicts -f /tmp/gotk-substituted.yaml
popd

# --- Hent known_hosts fra inde i clusteret og patch secreten ---
# Køres inde i clusteret så scriptet ikke er afhængig af netværksadgang til git-serveren
if kubectl get secret kubernetes-config-git-auth -n netic-gitops-system &>/dev/null; then
  git_host=$(echo "$1" | cut -d'/' -f1)
  ssh_port="${3:-7999}"

  kubectl run "${keyscan_pod}" \
    --image=alpine \
    --restart=Never \
    -- sh -c "apk add -q openssh-client 2>/dev/null && ssh-keyscan -p ${ssh_port} ${git_host} 2>/dev/null"

  kubectl wait pod "${keyscan_pod}" --for=jsonpath='{.status.phase}'=Succeeded --timeout=60s

  # Transformer output til korrekt known_hosts format: [host]:port key-type base64
  kubectl logs "${keyscan_pod}" | grep -v '^#' | \
    sed "s/^${git_host} /[${git_host}]:${ssh_port} /" > "${known_hosts_tmp}"

  kubectl delete pod "${keyscan_pod}" --ignore-not-found=true

  known_hosts_b64=$(base64 < "${known_hosts_tmp}" | tr -d '\n')
  kubectl patch secret kubernetes-config-git-auth \
    -n netic-gitops-system \
    --type=merge \
    -p "{\"data\":{\"known_hosts\":\"${known_hosts_b64}\"}}"
fi

# --- Bootstrap the cluster GitOps repo ---
git clone --depth 1 "https://${gitops_username}:${gitops_token}@$1" "${checkout_config}"

pushd "${checkout_config}/$2"
kubectl kustomize . | perl -pe 's/\$\{(\w+)(?::=([^}]*))?\}/$ENV{$1} \/\/ $2 \/\/ ""/ge' | kubectl apply --server-side --force-conflicts -f -
popd
