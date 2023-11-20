# Use pkgs provided by NUR
{ pkgs ? import <nixpkgs> { } }:

let
  flake = import ./compat.nix { src = ./.; };

  # Ignoring the NUR's nixpkgs revision:
  # final = pkgs.extend flake.outputs.overlay;
  final = flake.outputs.legacyPackages.${pkgs.system}.pkgs;
in
final.some-pkgs // {
  inherit (final) some-pkgs some-datasets some-util;
  inherit (final.some-pkgs) some-pkgs-py;
}
