{ lib
, stdenv
, fetchFromGitHub
, cmake
, xtensor
, enablePython ? false
, python3Packages
, catch2_3
}:

stdenv.mkDerivation rec {
  pname = "cppcolormap";
  version = "1.4.5";

  src = fetchFromGitHub {
    owner = "tdegeus";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-O/PaXYy4eyqx8GJosOvAGp7SiJ7p01wI757/YyUBi4g=";
  };

  nativeBuildInputs = [
    cmake
  ] ++ lib.optionals enablePython [
    python3Packages.python
  ];

  buildInputs = [
    xtensor
    catch2_3
  ] ++ lib.optionals enablePython [
    python3Packages.pybind11
  ];

  propagatedBuildInputs = with python3Packages; lib.optionals enablePython [
    numpy
    (xtensor-python.overridePythonAttrs (_: {
      format = "other";
    }))
  ];

  cmakeFlags = [
    "-DBUILD_TESTS=ON"
  ] ++ lib.optionals enablePython [
    "-DBUILD_PYTHON=ON"
  ];

  doCheck = true;

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  meta = with lib; {
    broken = true;
    description = "Library with colormaps for C++";
    homepage = "https://github.com/tdegeus/cppcolormap";
    platforms = lib.platforms.unix;
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
  };
}
