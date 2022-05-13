# Use the system-provided nixpkgs instead of the pinned dependencies
{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

pkgs.some-pkgs
