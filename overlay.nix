{ inputs }:
final: prev:


let
  lib' = prev.lib;
  inherit (import ./lib/extend-lib.nix { inherit inputs; oldLib = prev.lib; }) lib;

  inherit (lib) readByName autocallByName;

  toplevelFiles = readByName ./pkgs/by-name;
  pythonFiles = readByName ./python-packages/by-name;
in
{
  inherit lib;

  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (py-final: py-prev:
      let
        scope = py-final.some-pkgs-py;
        autocalled = (autocallByName scope ./python-packages/by-name);
        extra = {
          cppcolormap = py-final.toPythonModule (final.some-pkgs.cppcolormap.override {
            enablePython = true;
            python3Packages = py-final;
          });

          some-pkgs-faiss = py-final.toPythonModule (final.some-pkgs.faiss.override {
            pythonSupport = true;
            pythonPackages = py-final;
          });

          instant-ngp = scope.callPackage ./python-packages/by-name/in/instant-ngp/package.nix {
            lark = py-final.lark or py-final.lark-parser;
          };

          quad-tree-loftr = scope.quad-tree-attention.feature-matching;
        };
      in
      {
        some-pkgs-py = final.recurseIntoAttrs (autocalled // extra // {
          callPackage = py-final.newScope (py-final // final.some-pkgs // scope);
        });
      })
  ];

  inherit (final.python3Packages) some-pkgs-py;

  some-util = final.recurseIntoAttrs (final.callPackage ./some-util { });

  some-pkgs =
    final.recurseIntoAttrs
      ((autocallByName (final // final.some-pkgs) ./pkgs/by-name) //
      {
        some-pkgs-py = prev.recurseIntoAttrs final.python3Packages.some-pkgs-py;
        callPackage = final.newScope (final // final.some-pkgs.some-pkgs-py // final.some-pkgs);

        faiss = final.callPackage ./pkgs/by-name/fa/faiss {
          pythonPackages = final.python3Packages;
          swig = final.swig4;
        };
      });

  some-datasets = final.recurseIntoAttrs (import ./datasets { lib = final.lib; pkgs = final; });

  opencv4 = if final.config.cudaSupport then prev.opencv4.override { stdenv = final.cudaPackages.backendStdenv; } else prev.opencv4;

} // lib'.optionalAttrs (lib'.versionOlder lib'.version "23.11") {
  # 2023-08-28: NUR still uses the 23.05 channel which doesen't handle pythonPackagesExtensions
  python3 =
    let
      self = prev.python3.override {
        packageOverrides = lib'.composeManyExtensions final.pythonPackagesExtensions;
        inherit self;
      };
    in
    self;
  python3Packages = final.python3.pkgs;
}
