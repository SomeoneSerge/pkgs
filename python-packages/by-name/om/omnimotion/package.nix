{ lib
, bash
, buildPythonPackage
, configargparse
, fetchFromGitHub
, imageio
, imageio-ffmpeg
, kornia
, matplotlib
, opencv4
, python
, scipy
, setuptools
, some-util
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

      prefix = some-util.prefixPythonSubmodules { inherit pname dirSubmodules fileSubmodules; };
    in
    ''
      cat ${./pyproject.toml} > pyproject.toml

      ${prefix.sed}
      ${prefix.mv}
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

  postFixup = ''
    mkdir -p $out/bin

    buildPythonPath "$out $pythonPath"

    cat << EOF > $out/bin/${pname}-viz
    #!${lib.getExe bash}
    export PYTHONPATH=\$PYTHONPATH:$program_PYTHONPATH
    ${lib.getExe python} -m omnimotion.viz \$@
    EOF
    chmod a+x $out/bin/${pname}-viz
  '';

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
