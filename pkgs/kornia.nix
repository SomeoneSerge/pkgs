{ lib
, buildPythonPackage
, fetchFromGitHub
, pytorch
, setuptools
, pytest-runner
, pytest
, scipy
, pytestCheckHook
}:
buildPythonPackage rec {
  name = "kornia";
  version = "0.6.2";
  src = fetchFromGitHub {
    owner = "kornia";
    repo = name;
    rev = "v${version}";
    sha256 = "sha256-aORZyePTk+oTqs4VfCgeM5FZR+d8TV3yD54QfywqOHA=";
  };
  checkInputs = [ pytest-runner pytestCheckHook scipy ];
  disabledTestPaths = [ "test/test_contrib.py" "test/x" "test/feature" "test/geometry" "test/tracking" ];
  propagatedBuildInputs = [ pytorch ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.asl20;
    description = "Open Source Differentiable Computer Vision Library";
    homepage = "https://kornia.github.io/";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
