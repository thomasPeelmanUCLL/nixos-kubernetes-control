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

      # Lab workaround: the kubelet serving certificates do not currently
      # include node IP SANs, so metrics-server cannot validate them.
      # Replace this with properly issued kubelet serving certificates later.
      ${pkgs.kubectl}/bin/kubectl -n kube-system patch deployment metrics-server \
        --type=json \
        -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
    '';
  };
}
