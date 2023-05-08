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

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (final.callPackage ./python-overrides.nix { })
  ];

  # Some things we want to expose even outside some-pkgs namespace:
  inherit (final.some-pkgs) faiss;

  some-pkgs =
    {
      inherit (final.python3Packages)
        arxiv-py
        albumentations
        cppimport
        grobid-client-python
        datasette-render-images
        instant-ngp
        nvdiffrast
        opensfm
        ezy-expecttest
        imviz pyimgui dearpygui
        kornia
        accelerate
        geomstats
        geoopt
        gpytorch
        check-shapes
        gpflow
        gpflux
        timm
        trieste
        qudida
        quad-tree-attention
        quad-tree-loftr
        pynvjpeg
        safetensors;

      callPackage = final.lib.callPackageWith (final // final.some-pkgs);

      cnpy = final.callPackage ./pkgs/cnpy.nix { };
      cnpyxx = final.callPackage ./pkgs/cnpyxx.nix { };
      cppcolormap = final.callPackage ./pkgs/cppcolormap.nix { };

      alpaca-cpp = final.callPackage ./pkgs/alpaca-cpp.nix { };
      llama-cpp = final.some-pkgs.callPackage ./pkgs/llama.cpp { };

      faiss = final.callPackage ./pkgs/faiss {
        pythonPackages = final.python3Packages;
        swig = final.swig4;
      };

      lustre = final.callPackage ./pkgs/lustre { };
      zotfile = final.callPackage ./pkgs/zotfile.nix { };
    };
}
