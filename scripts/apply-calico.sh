#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubeconfig="/etc/kubernetes/cluster-admin.kubeconfig"

manifest_files=(
  "manifests/calico/calico-v3.30.2-vxlan.yaml"
)

for manifest in "${manifest_files[@]}"; do
  git -C "$repo_root" ls-files --error-unmatch "$manifest" >/dev/null
done

echo "This will apply the tracked Calico manifests to the current cluster:"
for manifest in "${manifest_files[@]}"; do
  echo "  - $manifest"
done
echo "Kubeconfig: $kubeconfig"
read -r -p "Type APPLY-CALICO to continue: " answer
if [[ "$answer" != "APPLY-CALICO" ]]; then
  echo "Cancelled; no manifests were applied."
  exit 1
fi

for manifest in "${manifest_files[@]}"; do
  kubectl --kubeconfig="$kubeconfig" apply -f "$repo_root/$manifest"
done

echo "Calico manifests applied. Keep Flannel running until workloads are recreated and verified."
