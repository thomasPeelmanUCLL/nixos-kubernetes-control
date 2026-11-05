# Control-node bootstrap

This repository is staged configuration, not a completed Kubernetes cluster.
The base module has not been evaluated or deployed on the target VM.

## Observed host

- NixOS 26.05, x86_64-linux.
- Interface ens3; IPv4 10.1.1.168/24.
- IPv6 router advertisements and outbound IPv6 ping work.
- One temporary and one non-temporary global IPv6 address were observed. Do not use the temporary address as a cluster endpoint. Address persistence still needs verification.
- Existing installation uses GRUB on /dev/sda, ext4 root and no configured swap.
- Existing account tom is in wheel.

## Apply the base module from the VM console

1. Keep console access open. Back up /etc/nixos/configuration.nix.
2. Copy modules/base.nix from this repository to /etc/nixos/modules/base.nix. Because the repository is private, use authenticated Git access or copy the file through the console; never put an access token in a committed file.
3. Add ./modules/base.nix to the existing imports list in /etc/nixos/configuration.nix, alongside ./hardware-configuration.nix.
4. Preserve existing bootloader, NetworkManager, user and system.stateVersion settings. Do not replace the complete configuration or hardware file.
5. Set a strong local password with passwd tom if needed. Never commit passwords or password hashes.
6. Run nixos-rebuild build first. Only if it succeeds, run nixos-rebuild test from the console.
7. Check systemctl status sshd --no-pager and ss -lntp. Test a separate SSH login as tom before running nixos-rebuild switch.

The module permits password SSH for tom temporarily and denies direct root SSH. It opens the host firewall for SSH; restrict access to your management source in CloudStack firewall/ACL rules. A private IPv4 address requires VPN/routing or a public-IP port-forwarding rule for off-network clients. IPv6 access requires client IPv6 connectivity and applicable CloudStack ingress rules.

## Before exposing SSH broadly

Add your SSH public key to users.users.tom.openssh.authorizedKeys.keys in the NixOS configuration. Test key-based login in a separate session, then set services.openssh.settings.PasswordAuthentication = false in the module. Never commit the private key.

## Kubernetes work remaining

Native Kubernetes, not K3s: one control-plane node and one worker. Kubernetes is intentionally not enabled by this commit.

Before enabling it: verify the pinned nixpkgs Kubernetes modules and package version, reserve stable node addresses, obtain worker details, choose and configure a dual-stack-capable CNI, select non-overlapping pod/service IPv4 and IPv6 CIDRs, configure certificates and worker bootstrap, and scope cluster firewall rules. Preserve IPv6 router-advertisement handling when enabling forwarding. Do not expose etcd or kubelet publicly.
