# Experimental native Kubernetes control plane

Not tested or evaluated on the target VM yet. Not a completed cluster or production blueprint. Uses the installed channel's Kubernetes 1.36.3 with a version assertion, not a locked nixpkgs source.

## Scope

Starts native Kubernetes master services, etcd, kubelet, kube-proxy, Flannel and lab easyCerts PKI. The control node is unschedulable for ordinary workloads. DNS is deliberately disabled until we deploy and validate a current DNS manifest. No worker is needed to test API readiness.

Node addresses are the observed 10.1.1.168 and non-temporary 2001:6a8:2880:1482:9ded:e550:24f2:1cf2. Reserve the IPv4 lease in CloudStack and verify IPv6 address persistence before relying on these values. Hostname changes may affect DHCP behavior: keep console access. The configuration does not convert DHCP/SLAAC to static networking. Never choose the temporary IPv6 address as the node endpoint.

Pod ranges: 10.244.0.0/16 and fd73:7ab4:1c90:100::/56. Service ranges: 10.96.0.0/16 and fd73:7ab4:1c90:200::/112. Check these against all networks and VPNs before first startup. IPv6 ULA pod egress masquerading is requested through Flannel and must be tested; node IPv6 connectivity does not prove pod connectivity.

API access intentionally uses private IPv4 at https://10.1.1.168:6443. Dual-stack pod/service networking does not require exposing the API publicly over IPv6. No public-IP API SAN or public port forwarding is configured. CFSSL also binds to private IPv4; etcd stays loopback with the module's easyCerts integration. Do not expose etcd, kubelet or CFSSL publicly. easyCerts is a lab compromise and needs replacement/review for production.

## Build before activation

Back up /etc/nixos and keep both the console and a working SSH session open. Obtain this private repository through authenticated Git access or copy its files without putting credentials in Git. Compare the files with the installed configuration. Preserve the hardware UUID.

Place configuration.nix, hardware-configuration.nix and the modules directory together under /etc/nixos, removing duplicate inline SSH declarations from the old configuration by using the new root file.

Run sudo nixos-rebuild build first. Stop and capture any evaluation/build error. Do not activate on a failed build. If successful, run sudo nixos-rebuild test from the console. This starts services and creates persistent PKI/etcd state; test activation is not a rollback of application data.

## Check after test activation

    ip -4 addr show dev ens3
    ip -6 addr show dev ens3
    ip -6 route
    sysctl net.ipv6.conf.ens3.accept_ra net.ipv6.conf.all.forwarding
    sudo systemctl --failed
    sudo systemctl status cfssl certmgr etcd kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy flannel --no-pager
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get --raw=/readyz
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get nodes -o wide
    sudo kubectl --kubeconfig=/etc/kubernetes/cluster-admin.kubeconfig get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.podCIDRs}{"\n"}{end}'

Bootstrap may take time; inspect journalctl for the failing service rather than resetting state. Verify API readiness, two pod CIDRs per node, IPv6 route retention and a new key-based SSH session. Only then consider sudo nixos-rebuild switch. Do not commit generated CA keys, tokens, kubeconfigs with credentials, or /var/lib/kubernetes.

## Remaining

Evaluate and build on host; validate PKI, runtime and Flannel; pin nixpkgs; settle stable addressing; add DNS; configure least-privilege worker enrollment and source-scoped firewall rules; join worker; test IPv4/IPv6 pod/service traffic, DNS, egress and MTU. No claim of working dual-stack is made until these tests pass.
