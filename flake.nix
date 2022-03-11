{
  description = "My personal NUR repository";
  inputs.nixpkgs-release.url = "github:NixOS/nixpkgs/nixos-21.11";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs-release, nixpkgs-unstable }:
    let
      inherit (nixpkgs-release) lib;
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      supportsPlatform = system: package: builtins.elem system package.meta.platforms;
      filterUnsupported = system: packages:
        let
          filters = [
            (name: supportsPlatform system)
            (name: package: !(package.meta.broken or true))
          ];
          f = name: package: builtins.all (f: f name package) filters;
        in
        lib.filterAttrs f packages;
      importPkgs = system: import ./default.nix {
        pkgs = nixpkgs-release.legacyPackages.${system};
      };
      allAttrs = forAllSystems (system: importPkgs system);
      allPackages = lib.mapAttrs (system: packages: builtins.removeAttrs packages [ "lib" "overlays" "modules" ]) allAttrs;
      supportedPackages = lib.mapAttrs filterUnsupported allPackages;
      outputs = {
        packages = supportedPackages;
        overlays = allAttrs.x86_64-linux.overlays;
      };
    in
    outputs;
}
