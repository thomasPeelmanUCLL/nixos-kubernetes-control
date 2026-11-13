{ lib, ... }:
{
  services.kubernetes.flannel.enable = lib.mkForce false;
  services.flannel.enable = lib.mkForce false;

  systemd.tmpfiles.rules = [
    "d /var/lib/kubelet/plugins_registry 0755 root root -"
  ];
}
