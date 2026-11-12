# NixOS Kubernetes control node

Declarative native Kubernetes control-plane configuration for the verified two-node CloudStack lab. This is a machine-specific deployment repository, not a generic template.

## Verified on 2026-11-13

- Control: `k8s-control-1`, private IPv4 `10.1.1.237`, interface `ens3`.
- Worker: `k8s-worker-1`, private IPv4 `10.1.1.71`.
- Kubernetes `1.36.3`; both nodes Ready.
- IPv4/IPv6 pod traffic passed in both directions.
- HTTP passed through IPv4 and IPv6 Service addresses and the Service DNS name.
- CoreDNS is defined in `manifests/coredns.yaml`; it is applied separately from the NixOS system.
- Ordinary workloads schedule on the worker; the control node retains its NoSchedule taints.

See [deployment and operations](docs/verified-deployment.md) for exact revisions, secret handling, build/apply steps, verification, and limitations.

## Repository entry point

```sh
nix build --no-update-lock-file --out-link ./result .#nixosConfigurations.k8s-control-1.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration dry-activate
# Review planned changes before the next command.
sudo nixos-rebuild switch --flake .#k8s-control-1
```

Run these inside the intended repository checkout on the control node. Do not rebuild from the unrelated minimal `/etc/nixos/configuration.nix`. Never reuse this node's hardware UUIDs, addresses, or authorized key for a different machine.

## Security and scope

Keep enrollment tokens, private keys, and generated certificates outside Git and the Nix store. Never disable store-signature or TLS verification to speed deployment. This is a tested lab configuration, not a production-hardening or high-availability design. No reboot recovery test was performed during this session.
