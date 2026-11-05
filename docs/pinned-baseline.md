# Tested baseline and pinned rebuild workflow

User-reported validation on 2026-11-05: API readiness passed; control node Ready on Kubernetes 1.36.3; no failed systemd units; a test pod received IPv4 and IPv6 addresses and pinged external IPv4/IPv6 destinations; Flannel nodes/get RBAC was fixed; API access from pods through the private endpoint and IPv4 API Service returned HTTP 200 after allowing TCP 6443 on mynet; CoreDNS became Ready; internal and external DNS resolved; a DNS query through the IPv6 kube-dns Service returned its AAAA record.

This does not establish cross-node networking, TCP DNS, arbitrary application Service routing, ingress, HA or production PKI. The worker is not yet configured. Node address persistence and reboot recovery remain untested.

## Pinning

flake.nix selects nixpkgs revision 7dcdd87373d72e7a2173e4db02e20d3d7f495cfd, matching the revision inspected for the installed 26.05.13446.7dcdd87373d7 source. It reuses configuration.nix and enables the Nix flake CLI features. No pod/service CIDRs, SSH key or disk settings are changed by the flake wrapper. The pinned build still requires verification on the VM.

Generate a real lock file on the node; no narHash or lock metadata has been invented in GitHub:

    cd ~/nixos-kubernetes-control
    git pull --ff-only
    nix --extra-experimental-features 'nix-command flakes' flake lock
    git add flake.lock
    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#k8s-control-1

Staging flake.lock makes it visible to the Git-backed flake source; it does not push it to GitHub. Inspect and preserve the generated lock file and have it committed to the repository after validation. Never put secrets in the lock file or repository.

If build succeeds, with the CloudStack console and a working SSH session open:

    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild test --flake .#k8s-control-1
    sudo systemctl --failed --no-pager
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get --raw=/readyz
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get nodes -o wide
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig -n kube-system get pods -l k8s-app=kube-dns

Also verify a fresh key-based SSH login and host IPv6. If healthy, persist with:

    sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#k8s-control-1

Use --flake .#k8s-control-1 for subsequent rebuilds from this repository. A plain nixos-rebuild command normally uses /etc/nixos and can select the older inline configuration. Plain kubectl-managed DNS manifests remain separate from OS rebuilds. Do not run flake updates casually: review the input revision and Kubernetes version assertion before upgrades.

## Reboot validation

Only after a successful switch and with CloudStack console access available, plan a reboot. After reconnecting, check hostname, ens3 IPv4/IPv6 addresses and default routes, failed systemd units, API readiness, node Ready state and CoreDNS rollout. Repeat DNS/IPv6 Service tests with the repository test client. DHCP/SLAAC addressing is not made static by a flake pin. Reserve addresses and investigate changes before modifying Kubernetes endpoint values.

If boot or networking fails, use the console and the previous NixOS boot generation. An OS rollback does not undo etcd or PKI data changes; never delete those directories as a generic repair step.
