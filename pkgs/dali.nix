{ lib
, system
, stdenv
, toPythonModule
, python
, buildPythonPackage
, fetchFromGitHub
, cmake
, cudaPackages ? { }
, opencv4
, libjpeg
, libtiff
, lmdb
, libsndfile
, libtar
, pkg-config
, ffmpeg
, cfitsio
, protobuf
, clang
, libclang
, runCommandNoCC
, rsync
}:

with cudaPackages;

let
  pyLibclang = runCommandNoCC "${python.pname}-${libclang.pname}"
    {
      buildInputs = [ rsync ];
    } ''
    dst="$out/lib/${python.libPrefix}/site-packages"
    mkdir -p $dst
    tar -xf ${libclang.src} clang-${libclang.version}.src/bindings/python/clang
    rsync "clang-${libclang.version}.src/bindings/python/clang/" "$dst/clang/" -rvP
    substituteInPlace "$dst/clang/cindex.py" --replace "libclang.so" "${lib.getLib libclang}/lib/libclang.so"
  '';
  dali-build =
    # stdenv.mkDerivation
    buildPythonPackage rec {
      pname = "dali";
      version = "1.23.0";

      src = fetchFromGitHub {
        owner = "NVIDIA";
        repo = "DALI";
        rev = "v${version}";
        hash = "sha256-JN+gK/YcW5QocqgsvZWJNYkXeDxoP9NfWJFDoZTD8SY=";
        fetchSubmodules = true;
      };

      # postPatch = ''
      #   substituteInPlace cmake/Dependencies.cmake --replace "Protobuf 2.0 REQUIRED" "Protobuf ${protobuf.version} REQUIRED"
      # '';

      nativeBuildInputs = [
        cmake
        cuda_nvcc
        pkg-config
        clang
        pyLibclang
      ];

      buildInputs = [
        opencv4
        cuda_cudart
        cuda_nvrtc
        cuda_nvtx
        libcurand
        libcublas
        libcufft
        libnvjpeg
        libjpeg
        libtiff
        lmdb.dev
        libsndfile
        libtar
        ffmpeg.dev
        cfitsio
        protobuf
      ];

      cmakeFlags = [
        # "-DCUDA_VERSION=${cudaMajorMinorVersion}"
        "-DWHL_PLATFORM_NAME=${system}"
        "-DCUDA_TARGET_ARCHS=${builtins.concatStringsSep ";" (builtins.map cudaFlags.dropDot cudaFlags.cudaCapabilities)}"
        "-DProtobuf_PROTOC_EXECUTABLE=${lib.getExe protobuf}"
        ((x: builtins.trace x x)
          "-DProtobuf_LIBRARIES=${protobuf}/lib/")
        ((x: builtins.trace x x)
          "-DProtobuf_INCLUDE_DIRS=${protobuf}/include")
      ];

      buildPhase = ''
        cmake --build .
      '';

      meta = with lib; {
        broken = true;
        description = "A GPU-accelerated library containing highly optimized
    building blocks and an execution engine for data processing to accelerate
    deep learning training and inference applications";
        homepage = "https://github.com/NVIDIA/DALI";
        license = licenses.asl20;
        maintainers = with maintainers; [ ];
      };
    };
in
dali-build
