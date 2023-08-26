{ lib
, stdenv
, fetchFromGitHub
, cmake
, sway
, iio-sensor-proxy
}:

stdenv.mkDerivation rec {
  pname = "sway-autorotate";
  version = "unstable-2023-05-16";

  src = fetchFromGitHub {
    owner = "emiljonsrud";
    repo = "sway_autorotate";
    rev = "118d7b7ef71b613ec5e6a8da6964aba911a85901";
    hash = "sha256-nwLrQTT9gA9RFy6Wijc1yRqf5uke2jmIHxlKlGfxCUI=";
  };

  nativeBuildInputs = [
    cmake
  ];

  postPatch = ''
    cp ${./CMakeLists.txt} ./CMakeLists.txt
    sed -i \
      -e 's|swaymsg|${sway}/bin/swaymsg|g' \
      -e 's|monitor-sensor|${pkgs.iio-sensor-proxy}/bin/monitor-sensor|g' \
      autorotate.cpp
  '';

  meta = with lib; {
    description = "Service to autorotate laptop screen in sway";
    homepage = "https://github.com/emiljonsrud/sway_autorotate/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
