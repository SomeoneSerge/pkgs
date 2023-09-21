{ lib, config, pkgs, ... }:
let
  inherit (pkgs.some-util.types) remoteFile;
  inherit (lib) types;
in
{
  options.datasets = lib.mkOption {
    type = types.attrsOf remoteFile;
  };
}
