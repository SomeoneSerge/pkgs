{ buildPackages
, buildPythonPackage
, cudaPackages
, description
, fetchFromGitHub
, lib
, pname
, pybind11
, src
, stdenv
, symlinkJoin
, torch
, version
, which
}:

buildPythonPackage rec {
  inherit pname src version;
  postPatch = ''
    sed -i '/cxx_args =/{ x; a cxx_args = [ "-std=c++14" ]
      }' setup.py
  '';

  CUDA_HOME = symlinkJoin {
    name = "cuda-unsplit";
    paths = [
      buildPackages.cudaPackages.cuda_nvcc
      cudaPackages.cuda_cccl
      cudaPackages.cuda_cudart
      cudaPackages.libcublas
      cudaPackages.libcusolver
      cudaPackages.libcusparse
    ];
  };
  nativeBuildInputs = [
    cudaPackages.backendStdenv.cc
    which
  ];
  buildInputs = [
    pybind11
  ];
  propagatedBuildInputs = [
    torch
  ];

  meta = with lib; {
    inherit description;
    homepage = "https://github.com/NVIDIA/flownet2-pytorch/tree/master/networks/resample2d_package";
    license = licenses.asl20;
    maintainers = with maintainers; [ SomeoneSerge ];
    platforms = platforms.all;
  };
}
