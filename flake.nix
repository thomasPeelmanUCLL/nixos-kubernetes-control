{
  description = "NixOS native Kubernetes control node on CloudStack";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/7dcdd87373d72e7a2173e4db02e20d3d7f495cfd";

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.k8s-control-1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./modules/calico.nix
        ./modules/worker-firewall.nix
        ./modules/worker-hostname.nix
        { nix.settings.experimental-features = [ "nix-command" "flakes" ]; }
      ];
    };
  };
}
