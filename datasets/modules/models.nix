{ lib, config, pkgs, ... }:
let
  inherit (lib) types;
  inherit (pkgs.some-util.types) remoteFile;
  Model = types.submodule {
    options.weights = lib.mkOption {
      type = types.attrsOf remoteFile;
    };
  };
in
{
  options.models = lib.mkOption {
    type = types.attrsOf Model;
  };
}
