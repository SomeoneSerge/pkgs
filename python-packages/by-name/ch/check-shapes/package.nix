{ lib
, buildPythonPackage
, fetchFromGitHub
, poetry-core
, lark
}:

buildPythonPackage rec {
  pname = "check-shapes";
  version = "1.1.1";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "GPflow";
    repo = "check_shapes";
    rev = "v${version}";
    hash = "sha256-FeZ61316vATGVPIX2OexQn6XJjiWDmrBKJMHVEnAxhQ=";
  };

  nativeBuildInputs = [
    poetry-core
  ];

  propagatedBuildInputs = [
    lark
  ];

  pythonImportsCheck = [ "check_shapes" ];

  meta = with lib; {
    description = "Library for annotating and checking tensor shapes";
    homepage = "https://github.com/GPflow/check_shapes";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
