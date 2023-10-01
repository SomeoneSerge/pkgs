{ lib
, buildPythonPackage
, fetchzip
, fetchFromGitHub
, scipy
, setuptools
, some-datasets
, some-util
, stdenv
, torch-kernel-generic
}:

let
  alt_cuda_kernel = torch-kernel-generic {
    pname = "${raft.pname}-alt-cuda-corr";
    inherit (raft) version;

    src = "${raft.src}/alt_cuda_corr";

    pythonImportsCheck = [
      "alt_cuda_corr"
    ];

    meta = with lib; {
      description = "alt_cuda_corr kernel for VideoFlow";
      homepage = "https://github.com/XiaoyuShi97/VideoFlow";
      # https://github.com/XiaoyuShi97/VideoFlow/blame/51489304db6e75fbdd9ff64d4656c1d120b5a673/README.md#L115
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
      platforms = platforms.all;
    };
  };
  raft = buildPythonPackage rec {
    pname = "raft";
    version = "unstable-2023-08-23";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "princeton-vl";
      repo = "RAFT";
      rev = "3fa0bb0a9c633ea0a9bb8a79c576b6785d4e6a02";
      hash = "sha256-kQumDUsLL2TM1Nz1T+S6NgOKMurgVHqytgkhB1PxvYM=";
    };

    postPatch =
      let
        dirSubmodules = [ "core" ];
        fileSubmodules = [ "demo" "evaluate" "train" ];

        prefix = some-util.prefixPythonSubmodules { inherit pname dirSubmodules fileSubmodules; };
      in
      ''
        cat ${./pyproject.toml} > pyproject.toml

        ${prefix.sed}

        find -iname '*.py' -exec \
          sed -i \
            -e 's/sys.path.append.*$/pass/' \
            -e 's/^import utils/import ${pname}.core.utils/' \
            -e 's/^from \b\(utils\|update\|extractor\|corr\)\b/from ${pname}.core.\1/' \
            '{}' '+'

        ${prefix.mv}
      '';

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      alt_cuda_kernel
      scipy
    ];

    pythonImportsCheck = [
      "${pname}.core"
      "${pname}.core.utils"
      "${pname}.core.corr"
      "${pname}.core.extractor"
      "${pname}.core.raft"
      "${pname}.core.update"
    ];

    passthru = rec {
      inherit alt_cuda_kernel;
      merged = (some-datasets.extendModules {
        modules = [{
          models.raft = { inherit weights; };
        }];
      }).config;
      weights = {
        default = {
          name = "${pname}-models.zip";
          urls = [
            # Source: https://github.com/princeton-vl/RAFT/blob/3fa0bb0a9c633ea0a9bb8a79c576b6785d4e6a02/download_models.sh#L2
            # Fails with 409
            "https://dl.dropboxusercontent.com/s/4j4z58wuv8o0mfz/models.zip"
          ];
          hash = "sha256-Ah5YnOeGdTVO93BN0yhqf6gQZENc/BNll23oWvZdngo=";
          cid = "QmdATn2Fmzmjo82U3qTFP123y55i7jKVoZe44khCTtZfew";
          fetcher = { urls, hash, ... }: fetchzip {
            inherit urls hash;
            extension = ".zip";
          };
        };
      };
    };

    meta = with lib; {
      description = "";
      homepage = "https://github.com/princeton-vl/RAFT";
      license = licenses.bsd3;
      maintainers = with maintainers; [ ];
      mainProgram = "raft";
      platforms = platforms.all;
    };
  };
in
raft
