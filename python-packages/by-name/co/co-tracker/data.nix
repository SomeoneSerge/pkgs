{ lib, fetchurl }:

let
  inherit (lib) types;
  remoteFileType = lib.types.submodule ({ config, ... }: {
    options.urls = lib.mkOption { type = types.listOf types.str; };
    options.hash = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    options.cid = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    options.package = lib.mkOption { type = types.package; };
    config = {
      package = lib.mkDefault (
        fetchurl {
          inherit (config) urls hash;
          recursiveHash = true;
          downloadToTemp = true;
          postFetch = ''
            mkdir -p "$out/data"
            mv "$downloadedFile" "$out/data/$name"
          '';
        }
      );
      urls = lib.mkIf (config.cid != null) (lib.mkAfter [
        "https://cloudflare-ipfs.com/ipfs/${config.cid}"
      ]);
    };
  });
  data =
    lib.evalModules
      {
        modules = [
          {
            options.weights = lib.mkOption {
              type = types.attrsOf (remoteFileType);
            };
          }
          {
            weights.stride_4_wind_8 =
              {
                urls = [ "https://dl.fbaipublicfiles.com/cotracker/cotracker_stride_4_wind_8.pth" ];
                hash = "sha256-WeyynBqdqYSWopnwYERYt+0I6qRq4VWUh6qriHoR00Q=";
                cid = "QmUT732kt71hSorGfrUwV3kX9VPTvJbXfH4XE9HwQmEm77";
              };
            weights.stride_4_wind_12 =
              {
                urls = [ "https://dl.fbaipublicfiles.com/cotracker/cotracker_stride_4_wind_12.pth" ];
                hash = "sha256-UBpO6xMPX3N/G1j+1DxgC4HRLkaWzMf6AZdG7fAT97g=";
                cid = "QmQpqnspXDPDShSUH9ive1syWFrSbvSUK26snS7gY6Qn9T";
              };
            weights.stride_8_wind_16 =
              {
                urls = [ "https://dl.fbaipublicfiles.com/cotracker/cotracker_stride_8_wind_16.pth" ];
                hash = "sha256-UBpO6xMPX3N/G1j+1DxgC4HRLkaWzMf6AZdG7fAT97g=";
                cid = "QmWhqJtdEFz8qZvYbUc4fra6iaRkAJgM7GqE6P3ZwdBFJt";
              };
          }
        ];
      };
in
data.config

