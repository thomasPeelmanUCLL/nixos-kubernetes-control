# Calico VXLAN Nix-native migration (control node)

This repository now carries a review-first Calico migration path for `k8s-control-1` without activating changes in this PR.

## What is configured declaratively

- `modules/calico.nix` disables:
  - `services.kubernetes.flannel`
  - `services.flannel`
- `modules/calico.nix` also declares:
  - `/var/lib/kubelet/plugins_registry`
- `manifests/calico/calico-v3.30.2-vxlan.yaml` is pinned to Calico `v3.30.2` and patched for:
  - Pod CIDR `10.244.0.0/16`
  - VXLAN encapsulation
  - `IP_AUTODETECTION_METHOD=interface=ens3`
  - BGP-disabled dataplane intent (`k8s,vxlan`)
- `manifests/calico/custom-resources.yaml` documents the corrected Installation resource values (`10.244.0.0/16`, `VXLAN`, `bgp: Disabled`, autodetection on `ens3`).

The pinned NixOS Kubernetes module in this repository does not expose a direct Calico deployment toggle comparable to Flannel, so the node-side Calico install remains a controlled, explicit activation step via tracked manifests.

## Build and dry-activation (no runtime switch yet)

From repository root on the control node:

```sh
nix build --no-update-lock-file --out-link ./result .#nixosConfigurations.k8s-control-1.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration dry-activate
```

Stop here for review. Do **not** run `nixos-rebuild switch` until you are ready for a coordinated migration window.

## Activation order (deliberate change window)

1. Build and dry-activate first (above).
2. During the change window, activate the NixOS config intentionally:
   ```sh
   sudo nixos-rebuild switch --flake .#k8s-control-1
   ```
3. Apply tracked Calico manifests with explicit confirmation:
   ```sh
   sudo ./scripts/apply-calico.sh
   ```

The script applies only Git-tracked files and always uses:

`/etc/kubernetes/cluster-admin.kubeconfig`

## Workload recreation and Flannel removal

Do not remove Flannel until Calico is healthy and workloads are recreated.

1. Recreate workloads so pods are re-networked on Calico.
2. Verify pod-to-pod and pod-to-service traffic.
3. Only then remove Flannel resources from the cluster.

This PR intentionally does not delete live Flannel resources.

## Verification checklist

- `kubectl get nodes -o wide`
- `kubectl -n kube-system get pods -o wide`
- `kubectl get pods -A -o wide` (new pod IPs in `10.244.0.0/16`)
- Cross-node traffic works.
- DNS lookup for `kubernetes.default.svc.cluster.local` succeeds from a recreated workload pod.
- Firewall path includes UDP `4789` and TCP `5473` from worker `10.1.1.71` to control `10.1.1.237`.

IPv6 control-plane configuration is left intact in NixOS, but this migration does not claim IPv6 Calico dataplane support because IPv6 Calico was not explicitly configured or validated here.

## Rollback

If validation fails:

1. Stop further migration actions.
2. Roll back to the prior NixOS generation on the control node.
3. Keep/restore Flannel before retrying Calico changes.
4. Re-validate node and workload networking before proceeding again.
