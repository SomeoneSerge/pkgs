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
  version = "0.6.3";
  src = fetchFromGitHub {
    owner = "kornia";
    repo = name;
    rev = "v${version}";
    sha256 = "sha256-7CpONUpuZX5FkRkWBj+VH3rWhbCmyNfYc+IzaaiLJ1w=";
  };
  checkInputs = [ pytest-runner pytestCheckHook scipy ];
  propagatedBuildInputs = [ pytorch ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.asl20;
    description = "Open Source Differentiable Computer Vision Library";
    homepage = "https://kornia.github.io/";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
