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
    readByName = import ./read-by-name.nix { lib = lib'; };

    autocallByName = ps: baseDirectory:
      let
        files = readByName baseDirectory;
        packages = lib.mapAttrs
          (name: file:
            ps.callPackage file { }
          )
          files;
      in
      packages;
  };

  inherit (lib) readByName autocallByName;

  toplevelFiles = readByName ./pkgs/by-name;
  pythonFiles = readByName ./pkgs-py/by-name;
in
{
  inherit lib;

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (py-final: py-prev:
      let
        autocalled = (autocallByName py-final ./pkgs-py/by-name);
        extra = {
          cppcolormap = py-final.toPythonModule (final.some-pkgs.cppcolormap.override {
            enablePython = true;
            python3Packages = py-final;
          });

          faiss = py-final.toPythonModule (final.faiss.override {
            pythonSupport = true;
            pythonPackages = py-final;
          });

          some-pkgs-faiss = py-final.toPythonModule (final.some-pkgs.faiss.override {
            pythonSupport = true;
            pythonPackages = py-final;
          });

          instant-ngp = py-final.callPackage ./pkgs-py/by-name/in/instant-ngp/package.nix {
            lark = py-final.lark or py-final.lark-parser;
          };

          quad-tree-loftr = py-final.quad-tree-attention.feature-matching;
        };
      in
      autocalled // extra // {
        some-pkgs-py = lib.mapAttrs (name: _: py-final.${name}) (autocalled // extra);
      })
  ];

  # Some things we want to expose even outside some-pkgs namespace:
  inherit (final.some-pkgs) faiss;

  some-pkgs =
    (autocallByName final.some-pkgs ./pkgs/by-name) //
    {
      inherit (final.python3Packages) some-pkgs-py;
      callPackage = final.lib.callPackageWith (final // final.some-pkgs);

      faiss = final.callPackage ./pkgs/by-name/fa/faiss {
        pythonPackages = final.python3Packages;
        swig = final.swig4;
      };
    };
}
