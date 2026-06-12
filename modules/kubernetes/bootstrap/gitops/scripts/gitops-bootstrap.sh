#!/usr/bin/env bash

# -E: ERR-trap nedarves til funktioner og subshells, ellers fanges fejl dér ikke
set -Eeo pipefail

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# Unik suffix per kørsel så parallelle kald ikke kolliderer på temp-filer
_run_id="$$-$(date +%s)"

export KUBECONFIG="$(pwd)/kvm-kubeconfig-${_run_id}.tmp"
echo "$KUBECONFIG_RAW" > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

# $1 = cluster_repo, $2 = bootstrap_path, $3 = gotk_repo, $4 = gotk_path, $5 = git_ssh_port
checkout_gotk="$(pwd)/gotk-bootstrap-${_run_id}"
checkout_config="$(pwd)/cluster-config-${_run_id}"
known_hosts_tmp="/tmp/known_hosts-${_run_id}"
keyscan_pod="ssh-keyscan-${_run_id}"
ssh_port="${5:-7999}"

log "Args: cluster_repo=$1  bootstrap_path=$2  gotk_repo=$3  gotk_path=$4  ssh_port=${ssh_port}"

# Dumpes ved enhver fejl, så CI-loggen altid har cluster-kontekst at arbejde med
dump_diagnostics() {
  log "===== DIAGNOSTICS (exit code $1, line $2) ====="
  log "--- Nodes ---"
  kubectl get nodes -o wide 2>&1 || true
  # Kun default + netic-gitops-system — undgå at lække navne på alt i clusteret i CI-loggen
  for ns in default netic-gitops-system; do
    log "--- Pods ($ns) ---"
    kubectl get pods -n "$ns" -o wide 2>&1 || true
    log "--- Events ($ns, seneste 30) ---"
    kubectl get events -n "$ns" --sort-by=.lastTimestamp 2>&1 | tail -30 || true
  done
  if kubectl get pod "$keyscan_pod" &>/dev/null; then
    log "--- Keyscan pod describe ---"
    kubectl describe pod "$keyscan_pod" 2>&1 | tail -30 || true
    log "--- Keyscan pod logs ---"
    kubectl logs "$keyscan_pod" --tail=30 2>&1 || true
  fi
  log "--- netic-gitops-system deployments ---"
  kubectl get deploy -n netic-gitops-system 2>&1 || true
  log "===== END DIAGNOSTICS ====="
}
trap 'rc=$?; [ $rc -ne 0 ] && dump_diagnostics $rc $LINENO; exit $rc' ERR

# Pod-oprydning skal ske før kubeconfig slettes — ellers har kubectl ingen adgang
trap 'kubectl delete pod "$keyscan_pod" --ignore-not-found=true 2>/dev/null || true; rm -f "$KUBECONFIG" "$known_hosts_tmp"; rm -rf "$checkout_gotk" "$checkout_config"' EXIT

gitops_username=$(echo "${netic_username}" | jq -Rr @uri)
gitops_token=$(echo "${netic_password}" | jq -Rr @uri)

# --- Apply Flux / gotk components ---
log "Cloning gotk repo: $3"
git clone --depth 1 "https://${gitops_username}:${gitops_token}@$3" "${checkout_gotk}"
log "Clone OK — entering ${checkout_gotk}/$4"

pushd "${checkout_gotk}/$4"
log "Applying gotk-components.yaml"
# Substituer ${var:=default}-placeholders med env-vars (flux envsubst-syntaks)
perl -pe 's/\$\{(\w+)(?::=([^}]*))?\}/$ENV{$1} \/\/ $2 \/\/ ""/ge' gotk-components.yaml | \
  kubectl apply --server-side --force-conflicts -f -
log "gotk-components applied"
popd

# --- Hent known_hosts fra inde i clusteret og patch secreten ---
# Køres inde i clusteret så scriptet ikke er afhængig af netværksadgang til git-serveren
if kubectl get secret kubernetes-config-git-auth -n netic-gitops-system &>/dev/null; then
  log "Patching kubernetes-config-git-auth known_hosts"
  git_host=$(echo "$1" | cut -d'/' -f1)

  # Image med ssh-keyscan præinstalleret — runtime 'apk add' fejler hvis
  # pod-nettet ikke kan nå alpines CDN (set på OVH). ghcr.io fremfor Docker Hub
  # pga. anonyme pull rate limits fra delte cloud-egress-IP'er.
  kubectl run "${keyscan_pod}" \
    --image="${keyscan_image:-ghcr.io/linuxserver/openssh-server:latest}" \
    --restart=Never \
    --command -- sh -c "ssh-keyscan -p ${ssh_port} ${git_host}"

  if ! kubectl wait pod "${keyscan_pod}" --for=jsonpath='{.status.phase}'=Succeeded --timeout=180s; then
    log "ERROR: keyscan pod did not succeed within 180s"
    dump_diagnostics 1 $LINENO
    exit 1
  fi

  kubectl logs "${keyscan_pod}" | grep -v '^#' | \
    sed "s/^${git_host} /[${git_host}]:${ssh_port} /" > "${known_hosts_tmp}"

  kubectl delete pod "${keyscan_pod}" --ignore-not-found=true

  known_hosts_b64=$(base64 < "${known_hosts_tmp}" | tr -d '\n')
  kubectl patch secret kubernetes-config-git-auth \
    -n netic-gitops-system \
    --type=merge \
    -p "{\"data\":{\"known_hosts\":\"${known_hosts_b64}\"}}"
  log "known_hosts patched"
fi

# --- Bootstrap the cluster GitOps repo ---
log "Cloning cluster config repo: $1"
git clone --depth 1 "https://${gitops_username}:${gitops_token}@$1" "${checkout_config}"
log "Clone OK — entering ${checkout_config}/$2"

pushd "${checkout_config}/$2"

manifest="$(kubectl kustomize .)"
if [[ -z "$manifest" ]]; then
  log "ERROR: kubectl kustomize produced no output in $(pwd)"
  log "Directory contents:"
  ls -la
  exit 1
fi

log "Kustomize OK — $(echo "$manifest" | grep -c '^kind:') resources fundet"
echo "$manifest" | perl -pe 's/\$\{(\w+)(?::=([^}]*))?\}/$ENV{$1} \/\/ $2 \/\/ ""/ge' | kubectl apply --server-side --force-conflicts -f -
log "Cluster bootstrap applied"
popd
