{ lib
, buildPythonPackage
, fetchFromGitHub
, scikit-learn
, pytorch
, pyro-ppl
}:
buildPythonPackage rec {
  pname = "gpytorch";
  version = "1.11";

  src = fetchFromGitHub {
    owner = "cornellius-gp";
    repo = "gpytorch";
    rev = "v${version}";
    sha256 = "sha256-cpkfjx5G/4duL1Rr4nkHTHi03TDcYbcx3bKP2Ny7Ijo=";
  };
  propagatedBuildInputs = [
    scikit-learn
    pytorch
    pyro-ppl
  ];

  dontUseSetuptoolsCheck = true;
  checkPhase = ''
    # python -m unittest discover
  '';
  pythonImportsCheck = [
    "gpytorch"
    "gpytorch.priors"
    "gpytorch.likelihoods"
    "gpytorch.variational"
  ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    license = lib.licenses.mit;
    description = "An implementation of Gaussian Processes in PyTorch";
    homepage = "https://gpytorch.ai";
    platforms = lib.platforms.unix;
  };
}
