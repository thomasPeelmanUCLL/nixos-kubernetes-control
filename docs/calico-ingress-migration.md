# Calico VXLAN and ingress-nginx migration

This runbook prepares the current two-node NixOS cluster to use Calico and ingress-nginx while preserving the working Flannel configuration until Calico is verified.

## Target parity with the old cluster

| Component | Old cluster | New cluster target |
| --- | --- | --- |
| CNI | Calico | Calico VXLAN |
| Network policy | Calico-enforced | Calico-enforced |
| Ingress | ingress-nginx | ingress-nginx |
| Ingress NodePorts | 31644/TCP and 31079/TCP | 31644/TCP and 31079/TCP |
| Cluster DNS | CoreDNS via kube-dns | CoreDNS via kube-dns, unchanged |

Do not run Calico and Flannel as the permanent CNI. Calico is installed first, workloads are moved to it, and Flannel is removed only after verification.

## Before starting

1. Confirm console access to both nodes.
2. Back up etcd state, Kubernetes PKI, and the current NixOS configuration.
3. Record the current Flannel system closure and confirm both nodes are Ready.
4. Ensure no production workload is running on this cluster.
5. Select an explicit Calico release; do not use an unpinned latest manifest.

Check the current Flannel state:

```sh
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide
kubectl get ds -A
kubectl get networkpolicy -A
```

## Install Calico

Run this on the control node from a clean checkout of the selected revision:

```sh
export CALICO_VERSION=v3.30.2
sudo ./scripts/install-calico.sh
```

The script requires an explicit `CALICO_VERSION`, validates that the manifest URL is reachable, and applies the Calico operator and Installation resource. Review the downloaded manifest before applying it. Do not disable TLS verification.

After installation, wait for readiness:

```sh
kubectl -n calico-system wait --for=condition=Available deployment --all --timeout=300s
kubectl get pods -n calico-system -o wide
kubectl get nodes -o wide
```

Calico VXLAN requires UDP 4789 between nodes. The current firewall continues to allow Flannel UDP 8472 during the migration; remove the Flannel rule only after Flannel is removed.

## Move workloads to Calico

Calico does not preserve existing Flannel pod networking. Recreate pods after Calico is healthy:

```sh
kubectl get pods -A -o wide
kubectl -n NAMESPACE rollout restart deployment/DEPLOYMENT
kubectl -n NAMESPACE rollout status deployment/DEPLOYMENT
```

Verify each recreated pod has an address in the expected pod CIDR and can reach CoreDNS:

```sh
kubectl run calico-dns-check --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/calico-dns-check --timeout=180s
kubectl exec calico-dns-check -- nslookup kubernetes.default.svc.cluster.local
kubectl delete pod calico-dns-check
```

Only after all workloads are healthy on Calico, remove Flannel:

```sh
kubectl -n kube-flannel delete daemonset kube-flannel-ds
kubectl -n kube-flannel delete serviceaccount flannel
kubectl -n kube-flannel delete configmap kube-flannel-cfg
kubectl delete clusterrole flannel
kubectl delete clusterrolebinding flannel
```

Then update both NixOS repositories to remove Flannel from the active configuration, rebuild, dry-activate, and persist the change.

## Install ingress-nginx

After Calico is the active CNI, install ingress-nginx with the old cluster's NodePorts:

```sh
./scripts/install-ingress-nginx.sh
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

The script installs the upstream Helm chart and pins:

- HTTP NodePort: 31644
- HTTPS NodePort: 31079
- Ingress class: nginx

Open the selected NodePorts in the worker firewall and CloudStack/public firewall before testing external access. Do not expose the Kubernetes API, etcd, or certificate service through ingress.

## Verification

Create a temporary test Ingress only after deploying a test backend. Verify:

- Both nodes are Ready.
- Calico pods are Running and no Flannel pods remain.
- A new pod receives a Calico-managed IP.
- Pod DNS resolves kubernetes.default.svc.cluster.local.
- Cross-node pod traffic passes.
- The ingress controller is Ready.
- HTTP reaches the test backend through NodePort 31644.
- HTTPS reaches the test backend through NodePort 31079 with a valid certificate.

## Rollback

Before removing Flannel, retain its manifests and current NixOS system closure. If Calico is not healthy, do not remove Flannel; delete the Calico installation and retain the prior configuration.

After Flannel is removed, rollback requires restoring the prior system closure and reinstalling/recreating the Flannel workload. This is why Flannel must remain active until Calico is verified.

## Scope

This prepares migration but does not itself make the cluster production-ready. It does not add HA, encrypted secrets, external IPv6 egress validation, backup/restore testing, or reboot recovery testing.
