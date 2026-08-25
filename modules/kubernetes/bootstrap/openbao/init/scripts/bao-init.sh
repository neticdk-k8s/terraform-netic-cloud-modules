#!/usr/bin/env bash
# Initialises OpenBao once, and only once.
#
# Idempotent by design: it asks the server whether it is already initialised
# before doing anything. Re-running `bao operator init` against existing storage
# fails, and a redeploy must not be blocked by a leftover state file, so the
# server itself is the source of truth — never the file.
#
#   $1 = path to write the init JSON to
#
# Env: KUBECONFIG_RAW, NAMESPACE, POD, CONTAINER, BAO_ADDR, BAO_CACERT,
#      RECOVERY_SHARES, RECOVERY_THRESHOLD

set -e

OUT="$1"

KUBECONFIG="$(mktemp)"
trap 'rm -f "$KUBECONFIG"' EXIT
printf '%s' "$KUBECONFIG_RAW" >"$KUBECONFIG"
export KUBECONFIG

# Run a bao command inside the server container. BAO_ADDR must use the service
# DNS name: the server certificate carries DNS SANs only, so 127.0.0.1 fails
# certificate validation.
bao_exec() {
  kubectl exec -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- \
    sh -c "BAO_ADDR='$BAO_ADDR' BAO_CACERT='$BAO_CACERT' $1"
}

# An uninitialised OpenBao is sealed, so its pod never becomes Ready and
# `kubectl wait` would block forever. Poll the API instead.
#
# On a freshly built cluster the pod does not exist yet either: GitOps still has
# to reconcile the HelmRelease and pull the image, so the first attempts fail
# with "pod not found". That is expected — keep polling.
: "${API_TIMEOUT:=600}"
attempts=$((API_TIMEOUT / 5))
echo "Waiting for the OpenBao API to answer (up to ${API_TIMEOUT}s)..."
status=""
for i in $(seq 1 "$attempts"); do
  if status="$(bao_exec 'bao status -format=json' 2>/dev/null)" && [ -n "$status" ]; then
    break
  fi
  # `bao status` exits 2 while sealed — that is still a valid answer.
  if status="$(bao_exec 'bao status -format=json' 2>/dev/null || true)" && \
     printf '%s' "$status" | grep -q '"initialized"'; then
    break
  fi
  sleep 5
done

if ! printf '%s' "$status" | grep -q '"initialized"'; then
  echo "ERROR: no usable response from 'bao status' after ${API_TIMEOUT}s." >&2
  echo "Check that the pod is running and that auto-unseal is configured:" >&2
  kubectl get pods -n "$NAMESPACE" >&2 || true
  exit 1
fi

if printf '%s' "$status" | grep -qE '"initialized":[[:space:]]*true'; then
  if [ -s "$OUT" ]; then
    echo "OpenBao is already initialised; keeping the existing init output."
    exit 0
  fi
  echo "ERROR: OpenBao is already initialised, but $OUT is missing or empty." >&2
  echo >&2
  echo "The root token and recovery keys are shown exactly once, at init time," >&2
  echo "and cannot be recovered afterwards. Supply the stored values instead of" >&2
  echo "re-running init — or, if this is a disposable environment, delete the" >&2
  echo "OpenBao storage and let it initialise from scratch." >&2
  exit 1
fi

echo "Initialising OpenBao (recovery shares=$RECOVERY_SHARES threshold=$RECOVERY_THRESHOLD)..."
umask 077
bao_exec "bao operator init -format=json \
  -recovery-shares=$RECOVERY_SHARES \
  -recovery-threshold=$RECOVERY_THRESHOLD" >"$OUT"

if ! grep -q '"root_token"' "$OUT"; then
  echo "ERROR: init did not return a root token. Output:" >&2
  cat "$OUT" >&2
  rm -f "$OUT"
  exit 1
fi

echo "OpenBao initialised. Root token and recovery keys written to $OUT"
