{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, prefix-python-modules
, edm
, torch
, torchvision
, imageio
, imageio-ffmpeg
, requests
, pillow
, scipy
, click
, pyspng
, python
}:

buildPythonPackage rec {
  pname = "edm";
  version = "unstable-2023-01-31";
  pyproject = true;

  pyprojectToml = ./pyproject.toml;

  src = fetchFromGitHub {
    owner = "NVlabs";
    repo = "edm";
    rev = "62072d2612c7da05165d6233d13d17d71f213fee";
    hash = "sha256-mCyC8JxTN+ng7Wswa9htBUeErKGuLlxPc6gbSmJIh4c=";
  };

  # Unfortunately, we cannot easily isolate edm's modules entirely and stay
  # compatible with the old pickles: it's not enough to map the names in the
  # Unpickler, because torch_info.persistence hard-codes the module names at
  # the application level (we'd have to rewrite the content of the pickles).
  #
  # We resort to the sys.modules hack, which means that it's safe to compose
  # edm with other modules in the same site-packages, but not in the same
  # python process
  postPatch = ''
    prefix-python-modules . --prefix "$pname"

    cat << EOF >> "$pname/__init__.py"
    import sys
    import $pname.torch_utils
    sys.modules["torch_utils"] = $pname.torch_utils
    EOF

    cat "$pyprojectToml" > pyproject.toml
  '';

  nativeBuildInputs = [
    setuptools
    prefix-python-modules
  ];

  propagatedBuildInputs = [
    torch
    torchvision
    imageio
    imageio-ffmpeg
    requests
    pillow
    scipy
    pyspng
    click
  ];

  pythonImportsCheck = [
    "edm.dataset_tool"
    "edm.fid"
    "edm.example"
    "edm.train"
    "edm.dnnlib.util"
  ];

  passthru.pythonWith = python.withPackages (_: [ edm ]);

  meta = with lib; {
    description = "Elucidating the Design Space of Diffusion-Based Generative Models (EDM)";
    homepage = "https://github.com/NVlabs/edm";
    license = licenses.cc-by-nc-sa-40;
    maintainers = with maintainers; [ ];
    mainProgram = "edm";
    platforms = platforms.all;
  };
}
