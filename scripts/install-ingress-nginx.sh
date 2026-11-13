#!/usr/bin/env bash
set -euo pipefail

namespace=ingress-nginx
release=ingress-nginx
chart=ingress-nginx/ingress-nginx

command -v helm >/dev/null || {
  echo "helm is required. Install it before running this script." >&2
  exit 1
}

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update

helm upgrade --install "$release" "$chart" \
  --namespace "$namespace" --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.default=true \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=31644 \
  --set controller.service.nodePorts.https=31079 \
  --wait --timeout=300s

kubectl -n "$namespace" rollout status deployment/ingress-nginx-controller --timeout=300s
kubectl -n "$namespace" get svc ingress-nginx-controller
