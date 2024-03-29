{
  description = "some-pkgs: sci-comp packages that have no place in nixpkgs";

  inputs.dream2nix.url = "github:nix-community/dream2nix";
  inputs.dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-gl-host.url = "github:SomeoneSerge/nix-gl-host"; # the jetson PR
  inputs.nix-gl-host.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = { self, dream2nix, nix-gl-host, nixpkgs }@inputs:
    let
      inherit (import ./lib/extend-lib.nix {
        inherit inputs;
        oldLib = nixpkgs.lib;
      })
        lib;
      systems =
        builtins.filter (name: builtins.hasAttr name nixpkgs.legacyPackages) [
          "x86_64-linux"
          "i686-linux"
          "x86_64-darwin"
          "aarch64-linux"
          "armv6l-linux"
          "armv7l-linux"
        ];
      forAllSystems = f: lib.genAttrs systems (system: f system);

      defaultPlatforms = [ "x86_64-linux" "aarch64-linux" ];

      supportsPlatform = system: name: package:
        let
          s = builtins.elem system (package.meta.platforms or defaultPlatforms);
        in
        s;

      reservedName = name: builtins.elem name [ "lib" "python" "python3" ];

      filterUnsupported = system: packages:
        let
          filters = [
            (name: _: !reservedName name)
            (name: attr: attr ? type && attr.type == "derivation")
            (supportsPlatform system)
          ];
          f = name: package: builtins.all (f: f name package) filters;
        in
        lib.filterAttrs f packages;

      overlay = import ./overlay.nix { inherit inputs; };

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        });

      newAttrs = forAllSystems (system:
        pkgs.${system}.some-pkgs // pkgs.${system}.some-pkgs.some-pkgs-py);
      supportedPkgs = lib.mapAttrs filterUnsupported newAttrs;

      outputs = {
        inherit overlay lib;

        packages = supportedPkgs;
        legacyPackages = newAttrs // (forAllSystems (system: {
          pkgs = pkgs.${system};
          pkgsUnfree =
            import nixpkgs {
              inherit system;
              config = { allowUnfree = true; };
              overlays = [ overlay ];
            };
          pkgsCuda =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
              };
              overlays = [ overlay ];
            };
          pkgsCudaCluster =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
                # Support V100s and A100s on the Aalto's "Triton" and RTX3090 at the lab:
                cudaCapabilities = [ "6.0" "7.0" "8.0" "8.6" ];
                cudaEnableForwardCompat = false;
              };
              overlays = [
                overlay
                (final: prev: {
                  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                    (py-final: py-prev: {
                      torch = py-prev.torch.override { MPISupport = true; };
                    })
                  ];
                })
              ];
            };
          pkgsCudaCompat =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
                cudaCapabilities = [ "5.2" ];
              };
              overlays = [ overlay ];
            };
          pkgsRocm =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                rocmSupport = true;
              };
              overlays = [ overlay ];
            };
          pkgsInsecureUnfree =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [ "openssl-1.1.1w" ];
              };
              overlays = [ overlay ];
            };
        } // lib.optionalAttrs (system == "aarch64-linux") {
          pkgsXavier =
            import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
                # Jetson AGX Xavier
                cudaCapabilities = [ "7.2" ];
                cudaEnableForwardCompat = false;
              };
              overlays = [ overlay ];
            };
        }));

        herculesCI.onPush.default.outputs =
          {
            fatCuda = with self.legacyPackages.x86_64-linux.pkgsCuda; {
              inherit (some-pkgs-py) stable-diffusion-webui instant-ngp nvdiffrast edm;
            };
            aalto = with self.legacyPackages.x86_64-linux.pkgsCudaCluster; {
              inherit (some-pkgs-py) stable-diffusion-webui instant-ngp nvdiffrast edm;
            };
            jetsons.xavier = with self.legacyPackages.aarch64-linux.pkgsXavier; {
              inherit (some-pkgs-py) edm nvdiffrast instant-ngp;
            };
          };
      };
    in
    outputs;
}
