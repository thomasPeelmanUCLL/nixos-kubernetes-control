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

if kubectl --kubeconfig="$kubeconfig" get installations.operator.tigera.io >/dev/null 2>&1; then
  echo "ERROR: a Tigera operator Installation already exists."
  echo "This repository uses the manifest-based Calico installation only."
  echo "Remove the operator Installation and its stale resources before continuing."
  exit 1
fi

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

echo "Calico manifests applied."
echo "Wait for calico-node pods to become ready before recreating workloads."
