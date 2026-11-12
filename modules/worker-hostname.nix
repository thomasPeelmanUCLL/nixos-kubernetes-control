{ ... }:
{
  # The API server may select the Node's Hostname for kubelet exec/logs.
  # Resolve it locally without depending on the upstream LAN DNS server.
  networking.extraHosts = ''
    10.1.1.71 k8s-worker-1
  '';
}
