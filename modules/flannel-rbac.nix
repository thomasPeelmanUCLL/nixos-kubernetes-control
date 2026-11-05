{ lib, ... }:
{
  # bootstrapAddons entries are shallow attrs: override the entire manifest,
  # not a nested rules field. Keep the existing flannel-client binding.
  services.kubernetes.addonManager.bootstrapAddons.flannel-cr = lib.mkForce {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "ClusterRole";
    metadata.name = "flannel";
    rules = [
      {
        apiGroups = [ "" ];
        resources = [ "pods" ];
        verbs = [ "get" ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "nodes" ];
        verbs = [ "get" "list" "watch" ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "nodes/status" ];
        verbs = [ "patch" ];
      }
    ];
  };
}
