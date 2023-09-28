{ lib
, buildPythonPackage
, configargparse
, fetchFromGitHub
, imageio
, imageio-ffmpeg
, kornia
, matplotlib
, opencv4
, scipy
, setuptools
, stdenv
, tensorboardx
, torch
, torchaudio
, torchvision
, tqdm
}:

buildPythonPackage rec {
  pname = "omnimotion";
  version = "unstable-2023-09-11";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "qianqianwang68";
    repo = "omnimotion";
    rev = "9576dd95477a65d65340425eb9c110853900f509";
    hash = "sha256-PwJbu/E5VPFvf35NxqGSlfcRXtWiX99oKZpAwh0QSKw=";
  };

  postPatch =
    let
      dirSubmodules = [ "networks" "loaders" "preprocessing" ];
      fileSubmodules = [ "config" "criterion" "train" "trainer" "util" "viz" ];

      moduleNames = dirSubmodules ++ fileSubmodules;

      submoduleFilesList = map (x: "${x}.py") fileSubmodules;
      submoduleDirsList = map (x: "${x}/") dirSubmodules;

      submoduleFiles = lib.concatStringsSep " " (map (x: ''"${x}"'') submoduleFilesList);
      submoduleDirs = lib.concatStringsSep " " (map (x: ''"${x}"'') submoduleDirsList);
      submoduleRegex = lib.concatStringsSep ''\|'' (map (x: ''\b${x}\b'') moduleNames);
    in
    ''
      cat ${./pyproject.toml} > pyproject.toml

      find -iname '*.py' -exec \
        sed -i \
          -e 's/^\(\s*import .*\)\(${submoduleRegex}\)\(.*\)$/\1${pname}.\2\3/' \
          -e 's/^\(\s*\)from \(${submoduleRegex}\)/\1from ${pname}.\2/' \
          '{}' '+'

      mkdir src/${pname} -p
      mv ${submoduleFiles} ${submoduleDirs} \
        src/${pname}/
    '';

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    configargparse
    imageio
    imageio-ffmpeg
    kornia
    matplotlib
    opencv4
    scipy
    tensorboardx
    torch
    torchaudio
    torchvision
    tqdm
  ];

  pythonImportsCheck = [
    "omnimotion.config"
    "omnimotion.criterion"
    "omnimotion.networks"
    "omnimotion.util"
    "omnimotion.viz"
  ];

  meta = with lib; {
    description = "";
    homepage = "https://github.com/qianqianwang68/omnimotion";
    license = licenses.asl20;
    maintainers = with maintainers; [ SomeoneSerge ];
    mainProgram = "omnimotion";
    platforms = platforms.all;
  };
}
