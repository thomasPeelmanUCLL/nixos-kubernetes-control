{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/control-plane.nix
    ./modules/flannel-rbac.nix
    ./modules/pod-api-access.nix
  ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  networking.networkmanager.enable = true;

  # Enroll with `sudo netbird up` after rebuilding; keep credentials out of Git.
  services.netbird.enable = true;

  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = [ pkgs.tree ];
  };
  environment.systemPackages = [ pkgs.wget ];
  system.stateVersion = "26.05";
}
