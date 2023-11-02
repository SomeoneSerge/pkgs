{ lib
, buildPythonPackage
, setuptools
, rope_1_10
, omnimotion
, prefix-python-modules
}:

let
  pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);
in
buildPythonPackage {
  pname = pyproject.project.name;
  version = pyproject.project.version;
  pyproject = true;

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    rope_1_10
    setuptools # pkg_resources for rope
  ];

  passthru.tests.omnimotion = omnimotion.overridePythonAttrs (oldAttrs:
    let
      inherit (oldAttrs) pname;
    in
    {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prefix-python-modules ];
      postPatch = ''
        find -iname '*.py' -exec sed -i 's/[[:space:]]*sys.path.append.*//' '{}' \;
        prefix-python-modules --prefix "$pname" .
        echo PYTHONPATH=$PYTHONPATH
        cp "$pyprojectToml" pyproject.toml
      '';
    });

  meta = with lib; {
    description = pyproject.project.description;
    homepage = "https://github.com/SomeoneSerge/pkgs";
    license = licenses.mit;
    mainProgram = pyproject.project.name;
    maintainers = with maintainers; [ SomeoneSerge ];
    platforms = platforms.all;
  };
}
