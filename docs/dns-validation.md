# CoreDNS and dual-stack DNS Service validation

These manifests are not deployed by nixos-rebuild or the legacy addon manager. Apply them explicitly with kubectl. Keep services.kubernetes.addons.dns.enable = false to avoid a second DNS installation. CoreDNS is pinned to release tag 1.15.0, not an image digest. Image pull and runtime compatibility still require validation.

One replica is placed on k8s-control-1 with explicit control-node tolerations. This is not redundant DNS. CoreDNS forwards non-cluster queries to Cloudflare public resolvers 1.1.1.1 and 1.0.0.1; change these upstreams if you need campus/private DNS resolution or a different privacy policy. No DNS ports are exposed publicly.

The Service uses IPv4 10.96.0.10 and IPv6 fd73:7ab4:1c90:200::a. The existing kubelet points pods to 10.96.0.10. A pod can query AAAA records over IPv4 DNS; DNS record family and DNS transport family are separate. Explicit IPv6-server queries below test IPv6 Service transport.

## Deploy

From the repository root:

    alias k='sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig'
    k apply --dry-run=server -f manifests/coredns.yaml
    k apply -f manifests/coredns.yaml
    k -n kube-system rollout status deployment/coredns --timeout=120s
    k -n kube-system get pods -l k8s-app=kube-dns -o wide
    k -n kube-system get service kube-dns -o yaml
    k -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns

Stop on errors. For a failed rollout, inspect k -n kube-system describe deployment coredns, describe the affected pod, and k -n kube-system logs deployment/coredns. Do not delete PKI or etcd.

## Test

    k apply -f manifests/tests/dns-client.yaml
    k wait --for=condition=Ready pod/dns-test --timeout=120s
    k exec dns-test -- cat /etc/resolv.conf
    k exec dns-test -- nslookup kubernetes.default.svc.cluster.local
    k exec dns-test -- nslookup -type=A kube-dns.kube-system.svc.cluster.local 10.96.0.10
    k exec dns-test -- nslookup -type=AAAA kube-dns.kube-system.svc.cluster.local 10.96.0.10
    k exec dns-test -- nslookup -type=A kube-dns.kube-system.svc.cluster.local fd73:7ab4:1c90:200::a
    k exec dns-test -- nslookup -type=AAAA kube-dns.kube-system.svc.cluster.local fd73:7ab4:1c90:200::a
    k exec dns-test -- nslookup example.com

Expected kube-dns A answer: 10.96.0.10. Expected AAAA answer: fd73:7ab4:1c90:200::a. The kubernetes.default Service may have only an A record because the API Service was initialized IPv4-first. Do not mistake that for a failure of the dual-stack DNS Service.

These tests validate ordinary pod DNS and UDP DNS routing via both Service families. They do not prove TCP DNS, arbitrary application Service routing, cross-node traffic, ingress or high availability.

Cleanup only the temporary client after collecting results:

    k delete -f manifests/tests/dns-client.yaml

Leave CoreDNS installed. Nixpkgs pinning and reboot/address-persistence validation remain separate steps. Never reboot without console access and a persisted system configuration.
