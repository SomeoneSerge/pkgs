{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      allPackages = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = lib.mapAttrs (system: packages: builtins.removeAttrs packages [ "lib" "overlays" "modules" ]) allPackages;
      overlays = allPackages.x86_64-linux.overlays;
    };
}
