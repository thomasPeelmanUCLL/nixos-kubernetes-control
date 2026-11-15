{ config, lib, pkgs, ... }:

{
  systemd.services.metrics-server-apply = {
    description = "Apply Kubernetes metrics-server manifests";
    after = [ "kube-apiserver.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [
        "KUBECONFIG=/etc/kubernetes/cluster-admin.kubeconfig"
      ];
    };

    script = ''
      ${pkgs.curl}/bin/curl -fsSL \
        https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml \
        -o /run/metrics-server-components.yaml

      ${pkgs.kubectl}/bin/kubectl apply --server-side \
        -f /run/metrics-server-components.yaml
    '';
  };
}
