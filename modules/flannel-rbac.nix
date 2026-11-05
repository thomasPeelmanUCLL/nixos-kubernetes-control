{ lib, ... }:
{
  # Preserve the bundled Flannel role's permissions and add nodes/get.
  # The existing flannel-crb binds this role to the flannel-client user.
  services.kubernetes.addonManager.bootstrapAddons.flannel-cr.rules = lib.mkForce [
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
}
