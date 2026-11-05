{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/control-plane.nix
    ./modules/flannel-rbac.nix
  ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  networking.networkmanager.enable = true;
  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = [ pkgs.tree ];
  };
  environment.systemPackages = [ pkgs.wget ];
  system.stateVersion = "26.05";
}
