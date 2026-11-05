{ ... }:
{
  # NixOS's bundled Flannel CNI uses the bridge named mynet.
  # Local pods reach the host-bound API through that interface, not ens3.
  # Also covers API Service traffic DNATed to the private API endpoint.
  # Keep other host ports filtered; do not trust the entire bridge.
  networking.firewall.interfaces.mynet.allowedTCPPorts = [ 6443 ];
}
