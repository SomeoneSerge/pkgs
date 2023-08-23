{ lib
, buildPythonPackage
, fetchFromGitHub
, pytorch
, setuptools
, pytest
, pytestCheckHook
, accelerate
, furo
, opencv4
, matplotlib
, pyyaml
, scipy
, torchvision
, packaging
  # For tests
, kornia
}:
buildPythonPackage rec {
  pname = "kornia";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "kornia";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-XcQXKn4F3DIgn+XQcN5ZcGZLehd/IPBgLuGzIkPSxZg=";
  };
  postPatch = ''
    substituteInPlace setup.py --replace "'pytest-runner'" ""
  '';

  buildInputs = [ packaging ];
  propagatedBuildInputs = [ pytorch ];
  checkInputs = [ pytestCheckHook scipy ];

  passthru.extras-require.x = [
    accelerate
    torchvision
    opencv4
    pyyaml
    matplotlib
  ];

  disabledTestPaths = [ "test/test_contrib.py" ];

  doCheck = false;
  passthru.tests.korniaTests = kornia.overridePythonAttrs (a: {
    doCheck = true;
  });

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.asl20;
    description = "Open Source Differentiable Computer Vision Library";
    homepage = "https://kornia.github.io/";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
