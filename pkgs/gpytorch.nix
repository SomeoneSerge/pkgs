{ lib
, buildPythonPackage
, fetchFromGitHub
, linear_operator
, pyro-ppl
, pytorch
, scikit-learn
}:
buildPythonPackage rec {
  pname = "gpytorch";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "cornellius-gp";
    repo = "gpytorch";
    rev = "v${version}";
    sha256 = "sha256-TBATjcSw95IHLGUkpj/+pTtprh272LqYtkOyQNfYgJ8=";
  };
  propagatedBuildInputs = [
    linear_operator
    pyro-ppl
    pytorch
    scikit-learn
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
