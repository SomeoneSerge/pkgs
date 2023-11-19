# Use pkgs provided by NUR
{ pkgs ? import <nixpkgs> { } }:

let
  flake = import ./compat.nix { };
  overlay = import ./overlay.nix { inherit (flake) inputs; };
  final = pkgs.extend overlay;
in
final.some-pkgs // {
  inherit (final) some-pkgs-py some-datasets some-util;
}
