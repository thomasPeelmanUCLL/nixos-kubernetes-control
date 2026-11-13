#!/usr/bin/env bash
set -euo pipefail

: "${CALICO_VERSION:?Set CALICO_VERSION to an explicit Calico release, for example v3.30.2}"

kubeconfig="${KUBECONFIG:-/etc/kubernetes/cluster-admin.kubeconfig}"
base="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests"
operator="${base}/tigera-operator.yaml"
custom_resource="${base}/custom-resources.yaml"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Downloading Calico ${CALICO_VERSION} manifests for review..."
curl --fail --location --silent --show-error \
  --output "$workdir/tigera-operator.yaml" "$operator"
curl --fail --location --silent --show-error \
  --output "$workdir/custom-resources.yaml" "$custom_resource"

echo "Review the manifests before continuing."
echo "Operator: $workdir/tigera-operator.yaml"
echo "Installation: $workdir/custom-resources.yaml"
read -r -p "Apply these Calico manifests? [y/N] " answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) echo "Cancelled; no changes applied."; exit 1 ;;
esac

kubectl --kubeconfig="$kubeconfig" create namespace tigera-operator --dry-run=client -o yaml | kubectl --kubeconfig="$kubeconfig" apply -f -
kubectl --kubeconfig="$kubeconfig" apply -f "$workdir/tigera-operator.yaml"
kubectl --kubeconfig="$kubeconfig" apply -f "$workdir/custom-resources.yaml"

echo "Waiting for Calico components..."
kubectl --kubeconfig="$kubeconfig" -n calico-system wait --for=condition=Available deployment --all --timeout=300s
kubectl --kubeconfig="$kubeconfig" get pods -n calico-system -o wide
kubectl --kubeconfig="$kubeconfig" get nodes -o wide
