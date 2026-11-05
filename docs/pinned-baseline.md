# Tested baseline and pinned rebuild workflow

User-reported validation on 2026-11-05: API readiness passed; control node Ready on Kubernetes 1.36.3; no failed systemd units; a test pod received IPv4 and IPv6 addresses and pinged external IPv4/IPv6 destinations; Flannel nodes/get RBAC was fixed; API access from pods through the private endpoint and IPv4 API Service returned HTTP 200 after allowing TCP 6443 on mynet; CoreDNS became Ready; internal and external DNS resolved; a DNS query through the IPv6 kube-dns Service returned its AAAA record.

The generated flake.lock was committed in 40e9658d31b532d5f6edcf820a5785f4b0e72e66. The local repository was then synchronized, the lock file was clean, and the pinned configuration built and switched successfully using:

    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#k8s-control-1

Post-switch validation reported no failed systemd units, API readiness ok, node k8s-control-1 Ready at 10.1.1.168, and CoreDNS 1/1 Running.

Reboot recovery was then validated. After reboot, the node retained IP 10.1.1.168, reported no failed systemd units, API readiness returned ok, Flannel was active, the node was Ready, and CoreDNS recovered to 1/1 Running. A replacement DNS test pod resolved the internal kubernetes.default Service, external example.com over IPv4 and IPv6, and the IPv6 kube-dns Service AAAA record. This validates control-node reboot recovery for the tested single-node baseline; it does not validate worker-node recovery or multi-node VXLAN forwarding.

The node carries node-role.kubernetes.io/master=true:NoSchedule and unschedulable=true:NoSchedule. The DNS test manifest therefore tolerates both taints. The unschedulable taint is not a standard automatic control-plane taint; investigate its intended purpose before removing it. Do not use these tolerations as a general pattern for ordinary workloads.

This does not establish cross-node networking, TCP DNS, arbitrary application Service routing, ingress, HA or production PKI. The worker is not yet configured.

## Pinned rebuild workflow

flake.nix selects nixpkgs revision 7dcdd87373d72e7a2173e4db02e20d3d7f495cfd, matching the revision inspected for the installed 26.05.13446.7dcdd87373d7 source. It reuses configuration.nix and enables the Nix flake CLI features. No pod/service CIDRs, SSH key or disk settings are changed by the flake wrapper.

The committed flake.lock pins nixpkgs revision 7dcdd87373d72e7a2173e4db02e20d3d7f495cfd with narHash sha256-tItrb9M8eYA6WhFgmT9tpGKueri3+wRuVA952o/2xSU=. Do not invent or manually edit lock metadata; regenerate it only when intentionally changing an input.

For normal rebuilds from this repository:

    cd ~/nixos-kubernetes-control
    git pull --ff-only
    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#k8s-control-1
    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild test --flake .#k8s-control-1

After validating a test activation, persist it with:

    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#k8s-control-1

A plain nixos-rebuild command normally uses /etc/nixos and can select the older inline configuration. Plain kubectl-managed DNS manifests remain separate from OS rebuilds. Do not run flake updates casually: review the input revision and Kubernetes version assertion before upgrades.

## Reboot validation

A reboot was performed with CloudStack console access available. After reconnecting, hostname, node IP, failed units, API readiness, node Ready state, Flannel status, CoreDNS rollout and DNS Service resolution were checked. Future reboots should repeat these checks. DHCP/SLAAC addressing is not made static by a flake pin. Reserve addresses and investigate changes before modifying Kubernetes endpoint values.

If boot or networking fails, use the console and the previous NixOS boot generation. An OS rollback does not undo etcd or PKI data changes; never delete those directories as a generic repair step.
