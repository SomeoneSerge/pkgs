{ lib
, buildPythonPackage
, fetchFromGitHub
, numpy
, pytorch
, scipy
, pytestCheckHook
, geoopt
}:

let
  pname = "geoopt";
  version = "0.5.1";
in
buildPythonPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "geoopt";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-AxbZ4I9lWx3JNnfkLHg40RpAwIsKxW2gqtjXG+t+wW8=";
  };

  buildInputs = [
    scipy # Only needed for rlinesearch.py
  ];

  propagatedBuildInputs = [
    numpy
    pytorch
  ];

  doCheck = false;
  checkInputs = [
    pytestCheckHook
  ];

  passthru.tests.geoopt-pytest = geoopt.overridePythonAttrs (_: { doCheck = true; });

  pythonImportsCheck = [
    "geoopt"
  ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.asl20;
    description = "Manifold aware pytorch.optim";
    homepage = "https://geoopt.readthedocs.io/";
    platforms = lib.platforms.unix;
  };
}
