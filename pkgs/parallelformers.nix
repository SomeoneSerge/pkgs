{ lib
, buildPythonPackage
, fetchFromGitHub
, dacite
, transformers
, torch
}:

let
  pname = "parallelformers";
  version = "1.2.7";
in
buildPythonPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "tunib-ai";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-ZmhcGyjtrH6lzZz0fCUVAd0GlmOMFhPmuVoTqwRjAX8=";
  };
  propagatedBuildInputs = [
    dacite
    transformers
    torch
  ];
  dontUseSetuptoolsCheck = true;
  pythonImportsCheck = [
    "parallelformers"
  ];

  meta = {
    maintainers = [ lib.maintainers.SomeoneSerge ];
    homepage = "https://github.com/tunib-ai/parallelformers";
    description = "Model parallelization library for huggingface transformers";
  };
}
