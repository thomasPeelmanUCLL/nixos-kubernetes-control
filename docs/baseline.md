# Installed control-node baseline

The root configuration.nix imports the hardware configuration and modules/base.nix. It preserves the installed GRUB disk, root UUID, NetworkManager backend, tom account and stateVersion. The SSH module contains the public key and disables password login. No private keys or password hashes belong in this repository.

This is not a completed Kubernetes configuration. It does not start Kubernetes, reserve node addresses or pin nixpkgs. It has not yet been evaluated on the target host. The existing docs/bootstrap.md describes the earlier password-enabled bootstrap stage; its manual SSH setup steps are superseded by the current key-only module.

## Safe deployment

Keep the CloudStack console and an existing SSH session open. Back up /etc/nixos before any changes. Use authenticated access to clone this private repository into a separate directory. Never put a GitHub token in a committed file.

Copy configuration.nix, hardware-configuration.nix and modules/base.nix into the corresponding locations under /etc/nixos only after comparing them with the installed files. Copy all three together: configuration.nix references the module. Do not also retain duplicate inline SSH settings.

Run sudo nixos-rebuild build. If successful, run sudo nixos-rebuild test, then test a second SSH login using the private key. Only after that succeeds, run sudo nixos-rebuild switch. A GitHub commit alone does not change the VM.

## Next cluster work

Target: native Kubernetes with one control-plane VM and one worker VM, IPv4/IPv6 dual-stack. Before enabling it, pin and verify the NixOS Kubernetes module/package version, settle stable node addresses, choose a dual-stack CNI, configure PKI and worker enrollment, and restrict cluster ports. Worker hardware configuration must come from the worker itself.
