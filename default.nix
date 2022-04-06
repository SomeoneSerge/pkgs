# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

let
  impureNixpkgs' = import <nixpkgs> { };
  impureNixpkgs = builtins.trace "ACHTUNG! Impure import <nixpkgs>" impureNixpkgs';
in
{ pkgs ? impureNixpkgs }:

rec {
  # The `lib`, `modules`, and `overlay` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  accelerate = pkgs.python3Packages.callPackage ./pkgs/accelerate.nix { inherit lib accelerate; };
  opensfm = pkgs.python3Packages.callPackage ./pkgs/opensfm { inherit lib; };
  kornia = pkgs.python3Packages.callPackage ./pkgs/kornia.nix { inherit lib accelerate kornia; };
}
