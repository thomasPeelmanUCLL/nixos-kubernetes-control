{ config, lib, pkgs, ... }:
let
  node4 = "10.1.1.168";
  node6 = "2001:6a8:2880:1482:9ded:e550:24f2:1cf2";
  pods4 = "10.244.0.0/16";
  pods6 = "fd73:7ab4:1c90:100::/56";
  services4 = "10.96.0.0/16";
  services6 = "fd73:7ab4:1c90:200::/112";
in
{
  # Experimental lab configuration: build and inspect before activation.
  networking.hostName = "k8s-control-1";
  networking.extraHosts = "${node4} k8s-control-1";
  environment.systemPackages = [ pkgs.kubectl ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.accept_ra" = 2;
    "net.ipv6.conf.ens3.accept_ra" = 2;
  };

  services.kubernetes = {
    package = pkgs.kubernetes;
    roles = [ "master" ];
    masterAddress = "k8s-control-1";
    apiserverAddress = "https://${node4}:6443";
    # Lab convenience only; do not treat this as production PKI.
    easyCerts = true;
    clusterCidr = "${pods4},${pods6}";

    apiserver = {
      bindAddress = node4;
      advertiseAddress = node4;
      securePort = 6443;
      serviceClusterIpRange = "${services4},${services6}";
      runtimeConfig = "";
      allowPrivileged = true;
      extraSANs = [ "k8s-control-1" node4 node6 "fd73:7ab4:1c90:200::1" ];
    };

    controllerManager.extraOpts = "--service-cluster-ip-range=${services4},${services6} --node-cidr-mask-size-ipv4=24 --node-cidr-mask-size-ipv6=64";
    kubelet = {
      address = node4;
      nodeIp = "${node4},${node6}";
      clusterDns = [ "10.96.0.10" ];
      unschedulable = true;
    };

    # Install DNS separately after verifying the control plane and CNI.
    addons.dns.enable = false;
    flannel = {
      enable = true;
      openFirewallPorts = false;
    };
  };

  services.flannel = {
    iface = "ens3";
    publicIp = node4;
    # The Flannel module expects an IPv4-only Network field.
    network = lib.mkForce pods4;
    extraNetworkConfig = {
      EnableIPv4 = true;
      EnableIPv6 = true;
      IPv6Network = pods6;
      IPv6SubnetLen = 64;
    };
  };
  systemd.services.flannel.environment.FLANNELD_IP_MASQ = "true";

  # Do not expose the certificate issuer on public interfaces.
  services.cfssl.address = lib.mkForce node4;

  # Only the private-bound API is opened now. Worker-specific CNI and
  # kubelet access rules are added once the worker address is known.
  networking.firewall.interfaces.ens3.allowedTCPPorts = [ 6443 ];

  assertions = [
    {
      assertion = config.services.kubernetes.package.version == "1.36.3";
      message = "This experimental module targets Kubernetes 1.36.3; review before changing the package version.";
    }
  ];
}
