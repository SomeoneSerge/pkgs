{
  description = "some-pkgs: sci-comp packages that have no place in nixpkgs";

  inputs.dream2nix.url = "github:nix-community/dream2nix";
  inputs.dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = { self, dream2nix, nixpkgs }@inputs:
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

      defaultPlatforms = [ "x86_64-linux" ];

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

      pkgsUnfree = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [ overlay ];
        });
      pkgsCuda = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
            cudaCapabilities = [ "8.6" ];
            cudaEnableForwardCompat = false;
          };
          overlays = [ overlay ];
        });
      pkgsRocm = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            rocmSupport = true;
          };
          overlays = [ overlay ];
        });
      pkgsInsecureUnfree = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "openssl-1.1.1w" ];
          };
          overlays = [ overlay ];
        });

      newAttrs = forAllSystems (system:
        pkgs.${system}.some-pkgs // pkgs.${system}.some-pkgs.some-pkgs-py);
      supportedPkgs = lib.mapAttrs filterUnsupported newAttrs;

      outputs = {
        inherit overlay lib;

        # packages = supportedPkgs;
        legacyPackages = newAttrs // (forAllSystems (system: {
          pkgs = pkgs.${system};
          pkgsUnfree = pkgsUnfree.${system};
          pkgsCuda = pkgsCuda.${system};
          pkgsRocm = pkgsRocm.${system};
          pkgsInsecureUnfree = pkgsInsecureUnfree.${system};
        }));
      };
    in
    outputs;
}
