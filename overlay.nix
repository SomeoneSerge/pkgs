final: prev:
let
  lib' = prev.lib;
  lib = lib'.recursiveUpdate lib' {
    maintainers.SomeoneSerge = {
      email = "sergei.kozlukov@aalto.fi";
      matrix = "@ss:someonex.net";
      github = "SomeoneSerge";
      githubId = 9720532;
      name = "Sergei K";
    };
  };
in
{
  inherit lib;

  pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
    (final.callPackage ./python-overrides.nix { })
  ];

  python =
    let
      self = prev.python.override {
        inherit self;
        packageOverrides = lib.composeManyExtensions final.pythonPackagesOverlays;
      }; in
    self;

  python3 =
    let
      self = prev.python3.override {
        inherit self;
        packageOverrides = lib.composeManyExtensions final.pythonPackagesOverlays;
      }; in
    self;

  pythonPackages = final.python.pkgs;
  python3Packages = final.python3.pkgs;

  some-pkgs = {
    inherit (final.python3Packages)
      instant-ngp
      opensfm
      pyimgui dearpygui
      kornia
      accelerate
      gpytorch
      gpflow
      gpflux
      quad-tree-attention
      quad-tree-loftr
      trieste;
  };
}
