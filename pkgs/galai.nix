{ buildPythonPackage
, fetchFromGitHub
, parallelformers
, bleach
, accelerate
, psutil
, spacy
}:

let
  pname = "galai";
  version = "1.0.0";
in
buildPythonPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "paperswithcode";
    repo = pname;
    rev = "56262670f811082e257f275e50469ccb8d67fa28";
    hash = "sha256-cso06y3YXlP5Hy4ljmnqo4DcVUIGuMPgcxhMqJIQ/sc=";
  };
  propagatedBuildInputs = [
    parallelformers
    accelerate
    bleach
    psutil
    spacy
  ];
}
