# Manifest-based Calico VXLAN installation

This branch uses **one** Calico installation method: the pinned manifest in
`manifests/calico/calico-v3.30.2-vxlan.yaml`.

Do not apply `manifests/calico/custom-resources.yaml`.
It is retained only as a deprecation notice.

## Why

The previous migration mixed a static Calico manifest with a Tigera operator
`Installation`. Those approaches can conflict because the operator expects to
manage the Calico installation, while the static manifest creates and manages
Calico resources directly.

The selected manifest provides:

- Calico CRDs
- VXLAN encapsulation
- Kubernetes API datastore mode
- Calico IPAM
- `portmap` CNI plugin support

## Controlled activation order

1. Build and switch the control node.
2. Apply only `manifests/calico/calico-v3.30.2-vxlan.yaml`.
3. Build and switch the worker node.
4. Wait for Calico pods to become ready.
5. Recreate workloads so they receive Calico networking.
6. Validate node readiness, pod CIDR allocation, DNS, and ingress.
7. Remove Flannel-specific cluster resources only after validation.

## Commands

On the control node:

```sh
cd ~/nixos-kubernetes-control-calico
nix build --no-update-lock-file --out-link ./result \
  .#nixosConfigurations.k8s-control-1.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration dry-activate
sudo nixos-rebuild switch --flake .#k8s-control-1
sudo ./scripts/apply-calico.sh
```

On the worker node:

```sh
cd ~/nixos-kubernetes-worker
nix build --no-update-lock-file --out-link ./result \
  .#nixosConfigurations.k8s-worker-1.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration dry-activate
sudo nixos-rebuild switch --flake .#k8s-worker-1
```

## Validation

```sh
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get nodes -o wide
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig \
  -n kube-system get pods -o wide
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig \
  -n ingress-nginx rollout restart deployment ingress-nginx-controller
```

New workload pods should receive addresses from `10.244.0.0/16`.
