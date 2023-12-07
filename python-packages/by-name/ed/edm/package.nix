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
, singularity-tools
, nixglhost
, prefixPythonModules ? true
, mkShell
, ncdu
, config
, formats
, pyprojectToml ? {
    build-backend.build-backend = "setuptools.build_meta";
    build-backend.requires = [ "setuptools" ];
    project.name = "edm";
    project.version = "2023.01.31";
    tool.setuptools.package-data = { };
    tool.setuptools.packages.find = lib.optionalAttrs (!prefixPythonModules) {
      include = [
        "dataset_tool*"
        "dnnlib*"
        "example*"
        "generate*"
        "torch_utils*"
        "train*"
        "training*"
      ];
    };
  }
, extraInit ? ''
    import logging
    logging.basicConfig(level=logging.DEBUG)
  ''
}:

assert (extraInit != null) -> prefixPythonModules;

buildPythonPackage ((lib.optionalAttrs (extraInit != null) {
  edmExtraInit = extraInit;
  passAsFile = [ "edmExtraInit" ];
}) // {
  pname = "edm";
  version = "unstable-2023-01-31";
  pyproject = true;

  pyprojectToml = "${(formats.toml { }).generate "pyproject.toml" pyprojectToml}";

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
    cat "$pyprojectToml" > pyproject.toml
  '' + lib.optionalString prefixPythonModules ''
    prefix-python-modules . --prefix "$pname"

    cat << EOF >> "$pname/__init__.py"
    import sys
    import $pname.torch_utils
    sys.modules["torch_utils"] = $pname.torch_utils
    EOF

    if [[ -n "''${edmExtraInit:-}" ]] ; then
      cat "$edmExtraInit" >> "$pname/__init__.py"
    fi

    find -iname '*.py' -exec sed -i 's/\(class_name\s*=\s*.\)training/\1edm.training/' '{}' ';'
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

  postFixup = lib.optionalString (!prefixPythonModules) ''
    cp *.py "$out/${python.sitePackages}/"
  '';

  pythonImportsCheck = map (x: if prefixPythonModules then "edm.${x}" else x) (
    [
      "train"
    ] ++ lib.optionals (!config.rocmSupport) [
      "torch_utils"
      "dataset_tool"
      "fid"
      "example"
      "dnnlib.util"
    ]
  );

  passthru.pythonWith = python.withPackages (_: [ edm ]);
  passthru.pythonWith' = (python.withPackages (ps: [
    edm
    ps.torch
    ps.typing-extensions
  ]));
  passthru.image = singularity-tools.buildImage {
    name = "edm";
    memSize = (if config.rocmSupport then 32 else 16) * 1024; # MiB (For squashfs compression to work properly)
    diskSize = (if config.rocmSupport then 32 else 16) * 1024; # MiB (Shrunk after the build)
    contents = [
      nixglhost
      ncdu
      (python.withPackages (ps: [
        edm
        ps.torch
        ps.typing-extensions
      ]))
    ];
  };

  meta = with lib; {
    description = "Elucidating the Design Space of Diffusion-Based Generative Models (EDM)";
    homepage = "https://github.com/NVlabs/edm";
    license = licenses.cc-by-nc-sa-40;
    maintainers = with maintainers; [ ];
    mainProgram = "edm";
    platforms = platforms.all;
  };
})
