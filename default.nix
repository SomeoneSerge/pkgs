# Use the system-provided nixpkgs instead of the pinned dependencies
let
  pkgs = import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; };
in

pkgs.some-pkgs
