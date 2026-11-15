{ config, lib, pkgs, ... }:
let
  control4 = "10.1.1.237";
  control6 = "2001:6a8:2880:1483:e632:18bb:42b5:3671";
  worker4 = "10.1.1.71";
  worker6 = "2001:6a8:2880:1483:7145:4d72:a74d:4a32";
  rules = [
    "${pkgs.iptables}/bin/iptables -w -A nixos-fw -i ens3 -s ${worker4}/32 -d ${control4}/32 -p tcp --dport 8888 -j nixos-fw-accept"
    "${pkgs.iptables}/bin/iptables -w -A nixos-fw -i ens3 -s ${worker4}/32 -d ${control4}/32 -p udp --dport 4789 -j nixos-fw-accept"
    "${pkgs.iptables}/bin/iptables -w -A nixos-fw -i ens3 -s ${worker4}/32 -d ${control4}/32 -p tcp --dport 5473 -j nixos-fw-accept"
  ];
in
{
  # Preserve existing SSH and API rules. Do not expose the issuer or
  # VXLAN to arbitrary hosts, including hosts on the global IPv6 subnet.
  networking.firewall.extraCommands = lib.concatStringsSep "\n" rules;
  networking.firewall.extraStopCommands = lib.concatMapStringsSep "\n"
    (rule: (builtins.replaceStrings [ "-A nixos-fw" ] [ "-D nixos-fw" ] rule) + " || true")
    rules;

  assertions = [
    {
      assertion = !config.networking.nftables.enable;
      message = "worker-firewall.nix requires the NixOS iptables firewall backend; review rules before enabling nftables.";
    }
    {
      assertion = config.networking.firewall.enable;
      message = "The cluster firewall rules require networking.firewall.enable.";
    }
  ];
}
