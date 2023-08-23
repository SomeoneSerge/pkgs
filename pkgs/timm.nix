{ lib
, buildPythonPackage
, fetchFromGitHub
, pytorch
, torchvision
, pytestCheckHook
, pytest-xdist
, ezy-expecttest
, huggingface-hub
}:


let
  pname = "timm";
  version = "0.9.5";
in
buildPythonPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "rwightman";
    repo = "pytorch-image-models";
    rev = "v${version}";
    hash = "sha256-6w5LlDTitGkg2foj7Asn47U+s6jJPc/33XYWm+R0WHM=";
  };

  # Bring your own instance
  buildInputs = [
    pytorch
    torchvision
  ];

  propagatedBuildInputs = [
    huggingface-hub
  ];

  checkInputs = [
    pytestCheckHook
    pytest-xdist
    ezy-expecttest
  ];

  preCheck = ''
    export GITHUB_ACTIONS=1
  '';
  pytestFlagsArray = [
    "./tests/"
    "-vvv"
    "--maxfail"
    "2"
    # Since there are just too many of them
    "-k"
    "resnet18d"
  ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.asl20;
    description = "PyTorch image models, scripts, weights. Used by Quad-Tree-Attention";
    homepage = "https://github.com/rwightman/pytorch-image-models";
    platforms = lib.platforms.unix;
  };
}
