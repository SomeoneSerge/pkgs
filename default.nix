# Use pkgs provided by NUR
{ pkgs ? import <nixpkgs> { } }:

let
  flake = import ./compat.nix { src = ./.; };
  final = pkgs.extend flake.outputs.overlay;
in
final.some-pkgs // {
  inherit (final) some-pkgs some-datasets some-util;
  inherit (final.some-pkgs) some-pkgs-py;
}
