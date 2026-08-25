# Cilium ↔ Istio compatibility

Applies the two Cilium settings that Istio needs in order to coexist with it,
as a `CiliumNodeConfig` override, and rolls the Cilium DaemonSet so the agents
pick them up.

**Only for clusters that run Istio.** Both settings cost something on a cluster
without a service mesh — see [When not to use this](#when-not-to-use-this).

## The problem

Without `cni-exclusive: false`, Cilium and Istio fight over the CNI config file:

```
Cilium  → rewrites /etc/cni/net.d/05-cilium.conflist, dropping Istio's plugin
Istio   → writes it back
Cilium  → drops it again
```

On a cluster we measured this at ~3 rewrites per second, per node. `istio-cni`
never becomes Ready, which blocks any GitOps Kustomization that waits on it —
and with it, anything downstream, such as certificate issuance.

Istio's own log names the cause:

> *Cilium CNI was detected; ensure 'cni.exclusive=false' in the Cilium configuration.*

## Why a CiliumNodeConfig and not the ConfigMap

On OVHcloud Managed Kubernetes, Cilium is installed by **OVH's own ArgoCD**.
Editing the `cilium-config` ConfigMap works for a few minutes and is then
reconciled back.

`CiliumNodeConfig` is a separate object that ArgoCD does not manage, so the
override survives. The side effect is that `cilium-config` keeps reporting the
original values — the manifest carries a comment saying so, because it is a
trap for whoever debugs this next.

## Usage

Run it **between cluster creation and the GitOps bootstrap**. Applied first, the
CNI conflict never happens; applied afterwards you also have to restart Cilium
while workloads are already running.

```hcl
module "cilium_istio_compat" {
  source     = ".../bootstrap/cilium-istio-compat"
  kubeconfig = module.service_cluster.kubeconfig

  depends_on = [module.service_cluster]
}

module "service_cluster_kubernetes_config" {
  source = ".../bootstrap/gitops"
  # ...
  depends_on = [module.cilium_istio_compat]
}
```

## Settings

| Option | Default | Why |
|---|---|---|
| `cni-exclusive` | `"false"` | Lets Istio chain its CNI plugin instead of having it stripped |
| `bpf-lb-sock-hostns-only` | `"true"` | Keeps Cilium's socket load balancing in the host namespace, so it does not short-circuit connections before the sidecar proxy sees them |

The second one fixes a failure you may not have hit yet: without it, mesh traffic
silently bypasses Istio rather than failing loudly.

## When not to use this

Set `enabled = false` on clusters without Istio. Both defaults are worse there:

- `cni-exclusive: false` — you want Cilium to own the CNI config exclusively,
  so stray plugins cannot attach themselves
- `bpf-lb-sock-hostns-only: true` — you give up socket load balancing in the pod
  namespace, which is otherwise a straight performance win

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kubeconfig` | `string` (sensitive) | — | Raw kubeconfig for the cluster |
| `enabled` | `bool` | `true` | Apply the overrides at all |
| `name` | `string` | `"cilium-istio-compat"` | Name of the CiliumNodeConfig |
| `namespace` | `string` | `"kube-system"` | Namespace Cilium runs in |
| `node_selector` | `map(string)` | `{}` | Nodes to target; empty = all nodes |
| `settings` | `map(string)` | see above | Cilium options to override |
| `restart_cilium` | `bool` | `true` | Roll the DaemonSet so agents reload |
| `cilium_daemonset` | `string` | `"cilium"` | DaemonSet to roll |
| `rollout_timeout` | `string` | `"5m"` | How long to wait for the rollout |

## Outputs

| Name | Description |
|------|-------------|
| `enabled` | Whether the overrides were applied |
| `name` | Name of the CiliumNodeConfig object |
| `settings` | The options that were overridden |

## Notes

- **The rollout briefly disrupts networking on every node.** That is the main
  reason to run this early, before workloads exist.
- **Cilium reads these at agent start**, so the restart is not optional on a
  running cluster — the object alone changes nothing until the agents reload.
- If the object was first applied by hand with `kubectl apply`, the first
  Terraform run takes over field ownership. The module uses server-side apply
  with `--force-conflicts`, so this resolves itself.
- The module waits for the `ciliumnodeconfigs.cilium.io` CRD before applying,
  and fails with a clear message if Cilium is not the CNI on the cluster.
- `kubectl` must be on `PATH` (same requirement as `bootstrap/gitops`).
