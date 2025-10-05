{
  description = "some-pkgs: sci-comp packages that have no place in nixpkgs";
  inputs.stable-flakes.url = "github:SomeoneSerge/stable-flakes";
  outputs =
    { stable-flakes, ... }:
    {
      legacyPackages = stable-flakes.lib.warn (
        stable-flakes.lib.forEachSystem (system: import ./default.nix { inherit system; })
      );
      overlays.default = stable-flakes.lib.warn (import ./overlay.nix);
      overlay = stable-flakes.lib.warn (import ./overlay.nix);
      inherit (stable-flakes) templates;
    };
}
