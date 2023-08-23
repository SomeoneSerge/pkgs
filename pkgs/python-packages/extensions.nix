{ pkgs, lib }: python-final: python-prev:

{
  accelerate = python-final.callPackage ./accelerate.nix { };

  arxiv-py = python-final.callPackage ./arxiv-py.nix { };

  albumentations = python-final.callPackage ./albumentations { };

  cppcolormap = python-final.toPythonModule (pkgs.some-pkgs.cppcolormap.override {
    enablePython = true;
  });

  cppimport = python-final.callPackage ./cppimport.nix { };


  faiss = python-final.toPythonModule (pkgs.faiss.override {
    pythonSupport = true;
    pythonPackages = python-final;
  });

  some-pkgs-faiss = python-final.toPythonModule (pkgs.some-pkgs.faiss.override {
    pythonSupport = true;
    pythonPackages = python-final;
  });

  grobid-client-python = python-final.callPackage ./grobid-client-python.nix { };

  imviz = python-final.callPackage ./imviz.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) Cocoa OpenGL CoreVideo IOKit;
  };
  pyimgui = python-final.callPackage ./pyimgui {
    inherit (pkgs.darwin.apple_sdk.frameworks) Cocoa OpenGL CoreVideo IOKit;
  };
  dearpygui = python-final.callPackage ./dearpygui {
    inherit (pkgs.darwin.apple_sdk.frameworks) Cocoa OpenGL CoreVideo IOKit;
  };

  datasette-render-images = python-final.callPackage ./datasette-plugins/datasette-render-images.nix { };

  ezy-expecttest = python-final.callPackage ./ezy-expecttest.nix { };

  nvdiffrast = python-final.callPackage ./nvdiffrast.nix { };

  opensfm = python-final.callPackage ./opensfm { };
  kornia = python-final.callPackage ./kornia.nix { };
  gpytorch = python-final.callPackage ./gpytorch.nix { };
  lpips = python-final.callPackage ./lpips.nix { };

  instant-ngp = python-final.callPackage ./instant-ngp {
    lark = python-final.lark or python-final.lark-parser;
  };

  geomstats = python-final.callPackage ./geomstats.nix { };
  geoopt = python-final.callPackage ./geoopt.nix { };

  check-shapes = python-final.callPackage ./check-shapes.nix { };
  gpflow = python-final.callPackage ./gpflow.nix { };
  gpflux = python-final.callPackage ./gpflux.nix { };
  trieste = python-final.callPackage ./trieste.nix { };

  timm = python-final.callPackage ./timm.nix { };

  quad-tree-attention = python-final.callPackage ./quad-tree-attention { };
  quad-tree-loftr = python-final.quad-tree-attention.feature-matching;

  qudida = python-final.callPackage ./qudida { };

  pynvjpeg = python-final.callPackage ./pynvjpeg.nix { };

  mask-face-gan = python-final.callPackage ./mask-face-gan.nix { };

  openai-clip = python-final.callPackage ./openai-clip.nix { };

  face-attribute-editing-stylegan3 = python-final.callPackage ./face-attribute-editing-stylegan3.nix { };

  safetensors = python-final.callPackage ./safetensors { };
}
