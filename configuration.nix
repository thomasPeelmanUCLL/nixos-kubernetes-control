{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Preserve the installed networking backend and current hostname.
  networking.networkmanager.enable = true;

  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = [ pkgs.tree ];
  };

  environment.systemPackages = [ pkgs.wget ];

  # Initial installation compatibility version; do not bump on upgrades.
  system.stateVersion = "26.05";

  # Kubernetes is intentionally not enabled in this baseline.
}
