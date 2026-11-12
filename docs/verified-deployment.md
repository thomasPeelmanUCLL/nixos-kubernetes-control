# Verified deployment and operations

## Evidence checkpoint: 2026-11-13

Configuration revisions before this documentation commit:

| Node | Repository | Configuration revision |
| --- | --- | --- |
| Control | thomasPeelmanUCLL/nixos-kubernetes-control | 2584895e5a69d32b87e3bf7baa15c857f8915613 |
| Worker | thomasPeelmanUCLL/nixos-kubernetes-worker | 778e14bbe478d5cb6862d69c316621362a100b5f |

Observed deployed systems:

- Control: `/nix/store/9xnv468lp6g33acbljyjmq88cdhd36jb-nixos-system-k8s-control-1-26.05.20261102.7dcdd87`.
- Worker: `/nix/store/451hd9l9hxj98wn5afyzryxbd0hdwyf8-nixos-system-k8s-worker-1-26.05.20261102.7dcdd87`.

Both used nixpkgs `7dcdd87373d72e7a2173e4db02e20d3d7f495cfd` and Kubernetes 1.36.3. System profile and running-system paths were checked; neither node was reboot-tested.

## Addresses and access

| Setting | Control | Worker |
| --- | --- | --- |
| Hostname | k8s-control-1 | k8s-worker-1 |
| Private IPv4 | 10.1.1.237 | 10.1.1.71 |
| Non-temporary IPv6 observed | 2001:6a8:2880:1483:e632:18bb:42b5:3671 | 2001:6a8:2880:1483:7145:4d72:a74d:4a32 |
| Interface | ens3 | ens3 |
| SSH via 193.191.187.103 | port 1222 | port 1223 |
| IPv4 pod allocation observed | 10.244.0.0/24 | 10.244.1.0/24 |
| IPv6 pod allocation observed | fd73:7ab4:1c90:100::/64 | fd73:7ab4:1c90:101::/64 |

The IPv6 addresses are SLAAC/dynamic, not guaranteed permanent allocations. Reserve/maintain node addresses and review host mappings, certificate SANs, node IPs, and peer firewall rules whenever addresses change.

Use the workstation key only from the workstation:

```sh
ssh -i ~/.ssh/id_isw -o IdentitiesOnly=yes -p 1222 tom@193.191.187.103
```

Never copy the workstation private key or cluster-admin credentials onto the worker.

## Source of truth

The running configurations were deployed from extracted Git snapshots, not from `/etc/nixos`. The original `/home/tom/nixos-kubernetes-control` checkout had local modifications and was deliberately not reset or overwritten. Future deployments must use an explicitly selected repository revision. Pulling or committing alone never activates a system.

## Repeat deployment without changing Nix trust

1. Fetch and select the desired revision in an authenticated workstation checkout.
2. Export tracked source with `git archive REVISION > control-source.tar`.
3. Transfer with `scp -i ~/.ssh/id_isw -o IdentitiesOnly=yes -P 1222 control-source.tar tom@193.191.187.103:/home/tom/`.
4. On the control node, extract into a fresh directory with `mktemp -d`; do not overwrite an existing dirty checkout.
5. Build there: `nix build --no-update-lock-file --out-link ./result .#nixosConfigurations.k8s-control-1.config.system.build.toplevel`.
6. Preview: `sudo ./result/bin/switch-to-configuration dry-activate`.
7. For network-sensitive changes, schedule a timed rollback to the captured old `/run/current-system`, run `switch-to-configuration test`, and verify a fresh SSH connection and cluster health before cancelling the timer.
8. Persist the reviewed configuration with `sudo nixos-rebuild switch --flake .#k8s-control-1`.
9. Compare `readlink -f /run/current-system` and `readlink -f /nix/var/nix/profiles/system`.

A workstation-to-server `nix copy` of an unsigned local build was rejected by the server's trusted-key policy. Building the exported source on the destination avoided weakening trusted users or signature enforcement. A timed test rollback is best-effort and is not a substitute for console access, backups, or a recovery plan.

## Addon installation

The built-in NixOS DNS addon is disabled intentionally. Review and apply the committed manifest from the control checkout:

```sh
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig apply -f manifests/coredns.yaml
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig -n kube-system rollout status deployment/coredns --timeout=120s
```

The committed manifest defines a control-node placement, tolerations, CoreDNS RBAC, and kube-dns Service IPs `10.96.0.10` and `fd73:7ab4:1c90:200::a`. Review these values when creating a different cluster. Manifests in Git are not automatically applied by the flake.

## Enrollment and scheduling

Worker enrollment needs `/var/lib/kubernetes/secrets/ca.pem` and `apitoken.secret`, transferred securely from the trusted control node. Verify the issuer using the installed CA, never `--insecure`. The worker sets `pkiTrustOnBootstrap = false`. Do not regenerate the existing CA or token merely to redeploy.

In this pinned NixOS module, kubelet `unschedulable = true` adds the custom `unschedulable=true:NoSchedule` registration taint; it does not set Node `.spec.unschedulable`. The worker now declares `false`. Its existing API-side taint was removed once with:

```sh
sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig taint nodes k8s-worker-1 unschedulable:NoSchedule-
```

Inspect current taints before changing them. Leave the control node's master and unschedulable taints intact. Registration flags do not reconcile all existing Node state.

## Verified checks

- Both nodes Ready; worker services active and no failed units at the checkpoint.
- A pod without nodeName or custom tolerations was scheduled on the worker.
- Test pods obtained both IPv4 and IPv6 addresses.
- Cross-node IPv4 and IPv6 pings passed in both directions with zero packet loss.
- A worker-hosted BusyBox HTTP server returned `worker-http-ok` through a RequireDualStack Service's IPv4 and IPv6 ClusterIPs and its cluster DNS name.
- Worker pod DNS resolved kubernetes.default.svc.cluster.local through 10.96.0.10.
- Worker exec initially failed because the control node could not resolve k8s-worker-1. modules/worker-hostname.nix fixed this declaratively.

Test addresses are ephemeral; discover them each run. These checks do not establish external IPv6 egress, load-balancer behavior, storage durability, HA, policy enforcement, production security, or post-reboot recovery.

## Cleanup and maintenance

Temporary test namespace: `k8s-netcheck`. Cleanup was suggested but not confirmed. Inspect before deleting; `kubectl delete namespace k8s-netcheck` removes all resources inside it. The older default/dns-test pod was observed Unknown and was not deleted. Do not remove cluster secret directories or the running CoreDNS addon.

Keep the current working snapshots until a deliberate maintenance pass. Consolidate the long-term checkout/deployment path without overwriting local changes. Back up cluster state and PKI securely before reinstalling nodes.
