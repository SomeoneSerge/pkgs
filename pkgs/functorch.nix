{ lib
, config
, buildPythonPackage
, fetchFromGitHub
, pytorch
, ninja
, cudatoolkit
, hip
, which
, cudaSupport ? config.cudaSupport or false
}:

let
  pname = "functorch";
  version = "0.1.1";
in
buildPythonPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "pytorch";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-FidM04Q3hkGEDr4dthJv0MWtGiRfnWxJoyzu7Wl3SD8=";
  };

  preConfigure = lib.optionalString cudaSupport ''
    export CUDA_HOME=${cudatoolkit}
  '';

  buildInputs = [
    pytorch
  ] ++ lib.optionals cudaSupport [
    cudatoolkit
  ];

  nativeBuildInputs = [
    ninja
    hip
    which
  ];

  pythonImportsCheck = [ "functorch" ];

  disabled = lib.versionOlder pytorch.version "1.11.0";

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.bsd3;
    description = "JAX-like composable function transforms for PyTorch";
    homepage = "https://pytorch.org/functorch/";
  };
}
