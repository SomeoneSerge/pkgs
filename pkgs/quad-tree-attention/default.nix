{ lib
, buildPythonPackage
, fetchFromGitHub
, pytorch
, cudaPackages
, symlinkJoin
, which
, ninja
, cudaArchList ? [ "8.6+PTX" ] # pytorch.cudaArchList
}:
let
  lastUpdated = "2022-04-21";
  version = "unstable-${lastUpdated}";

  src = fetchFromGitHub {
    owner = "Tangshitao";
    repo = "QuadTreeAttention";
    rev = "347ae9683a2061806def5aa4991ed797f7ef135c";
    hash = "sha256-h1GK35FiC1Rn+MJ1sAqIIqEDjd4aTnWKL86Q0XUWbyQ=";
  };

  feature-matching = buildPythonPackage {
    pname = "FeatureMatching";
    inherit version;

    format = "flit";

    src = "${src}/FeatureMatching";
    postPatch = ''
      mv src FeatureMatching
      cp train.py FeatureMatching/train.py

      find -iname '*.py' -exec sed -i 's/^from src\./from FeatureMatching./' '{}' +

      cat << EOF > pyproject.toml
      [build-system]
      requires = ["flit_core"]
      build-backend = "flit_core.buildapi"

      [project]
      name = "FeatureMatching"
      version = "0.0.1"
      description = "LoFTR with Quad Tree Attention"

      [projects.scripts]
      train = "FeatureMatching:train"
      EOF
    '';

    pythonCheckImports = [ "FeatureMatching" ];

    meta = with lib; {
      maintainers = [ maintainers.SomeoneSerge ];
      platforms = platforms.unix;
    };
  };

  cudaJoined = symlinkJoin {
    name = "cudatoolkit-root";
    paths = with cudaPackages; [
      cuda_nvcc
      cuda_nvrtc
      cuda_cudart
      libcublas
      libcusparse
      libcusolver
      cuda_cccl # <thrust/*>
    ];
    postBuild = ''
      ln -s $out/lib $out/lib64
    '';
  };

  quad-tree-attention = buildPythonPackage {
    pname = "QuadTreeAttention";
    inherit version;

    src = "${src}/QuadTreeAttention";

    # THCState removed from pytorch
    # they weren't using that variable anyway
    postPatch = ''
      sed -i '/extern THCState/d' QuadtreeAttention/src/value_aggregation.cpp
    '';

    buildInputs = [
      pytorch.dev
    ];
    nativeBuildInputs = [
      which
      ninja
    ];

    CUDA_HOME = "${cudaJoined}";
    TORCH_CUDA_ARCH_LIST = "${lib.concatStringsSep ";" cudaArchList}";

    passthru = {
      inherit feature-matching;
      inherit pytorch;
    };

    meta = with lib; {
      maintainers = [ maintainers.SomeoneSerge ];
      platforms = platforms.linux;
      broken = !pytorch.cudaSupport;
    };
  };
in
quad-tree-attention
