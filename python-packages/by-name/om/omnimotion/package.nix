{ lib
, bash
, buildPythonPackage
, callPackage
, configargparse
, dino
, fetchFromGitHub
, fetchzip
, imageio
, imageio-ffmpeg
, kornia
, matplotlib
, omnimotion
, opencv4
, python
, raft
, runCommand
, scipy
, setuptools
, some-datasets
, some-util
, stdenv
, tensorboardx
, torch
, torchvision
, tqdm
}:

buildPythonPackage rec {
  pname = "omnimotion";
  version = "unstable-2023-09-11";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "qianqianwang68";
    repo = "omnimotion";
    rev = "9576dd95477a65d65340425eb9c110853900f509";
    hash = "sha256-PwJbu/E5VPFvf35NxqGSlfcRXtWiX99oKZpAwh0QSKw=";
  };

  outputs = [ "out" "configs" ];

  postPatch =
    let
      dirSubmodules = [ "networks" "loaders" "preprocessing" ];
      fileSubmodules = [ "config" "criterion" "train" "trainer" "util" "viz" ];

      prefix = some-util.prefixPythonSubmodules { inherit pname dirSubmodules fileSubmodules; };
    in
    ''
      cat ${./pyproject.toml} > pyproject.toml

      substituteInPlace preprocessing/extract_dino_features.py \
        --replace "utils" "dino.utils" \
        --replace "vision_transformer" "dino.vision_transformer"

      substituteInPlace preprocessing/exhaustive_raft.py \
        --replace "from raft" "from raft.core.raft" \
        --replace "from utils" "from raft.core.utils" \
        --replace ", default='models/raft-things.pth'" ""

      substituteInPlace preprocessing/filter_raft.py \
        --replace "from chain_raft" "from omnimotion.preprocessing.chain_raft"

      ${prefix.sed}
      ${prefix.mv}
    '';

  nativeBuildInputs = [
    setuptools
  ];
  propagatedBuildInputs = [
    configargparse
    imageio
    imageio-ffmpeg
    kornia
    matplotlib
    opencv4
    scipy
    tensorboardx
    torch
    torchvision
    tqdm
  ];

  postInstall = ''
    mkdir -p $configs/data/${pname}
    cp -rf configs/* $configs/data/${pname}
  '';

  postFixup = ''
    mkdir -p $out/bin

    buildPythonPath "$out $pythonPath"

    cat << EOF > $out/bin/${pname}-viz
    #!${lib.getExe bash}
    export PYTHONPATH=\$PYTHONPATH:$program_PYTHONPATH
    ${lib.getExe python} -m omnimotion.viz \$@
    EOF
    chmod a+x $out/bin/${pname}-viz

    cat << EOF > $out/bin/${pname}-viz-default
    #!${lib.getExe bash}
    export PYTHONPATH=\$PYTHONPATH:$program_PYTHONPATH
    ${lib.getExe python} -m omnimotion.viz --config=$configs/data/${pname}/default.txt \$@
    EOF
    chmod a+x $out/bin/${pname}-viz-default
  '';

  pythonImportsCheck = [
    "omnimotion.config"
    "omnimotion.criterion"
    "omnimotion.networks"
    "omnimotion.util"
    "omnimotion.viz"
  ];

  passthru = rec {
    merged =
      let
        OverridePackage = with lib; with lib.types; submodule ({ config, name, ... }: {
          name = mkDefault "${name}.zip";
          package = fetchzip { inherit (config) urls hash; extension = ".zip"; };
        });
        m = lib.evalModules {
          modules = with lib; with lib.types; with some-util.types; [
            { options.examples = mkOption { type = attrsOf RemoteFile; }; }
            { options.examples = mkOption { type = attrsOf OverridePackage; }; }
            { inherit examples; }
            ({ config, ... }: {
              options.visualizations = mkOption { type = attrsOf package; };
              config.visualizations = lib.genAttrs
                (builtins.attrNames config.examples)
                (name:
                  let example = config.examples.${name}.package;
                  in
                  runVisualizer
                    {
                      checkpoint = "${example}/model*.pth";
                      dataDir = "${example}";
                      maskPath = "${example}/mask_0.png";
                    });
              options.modelDescriptions = mkOption { type = attrsOf package; };
              config.modelDescriptions = lib.genAttrs
                (builtins.attrNames config.examples)
                (name:
                  let example = config.examples.${name}.package;
                  in
                  runCommand "model.txt"
                    {
                      nativeBuildInputs = [ (python.withPackages (ps: [ ps.omnimotion ])) ];
                      checkpoint = "${example}/model*.pth";
                    }
                    ''
                      python << EOF | tee $out
                      import glob
                      import os
                      import torch
                      from pprint import pprint

                      def describe(x):
                        if isinstance(x, dict):
                          return {name: describe(y) for name, y in x.items()}
                        elif isinstance(x, (list, tuple)):
                          return [describe(y) for y in x]
                        elif isinstance(x, (int, float, str)):
                          return x
                        elif isinstance(x, torch.Tensor):
                          desc = {
                            "dtype": str(x.dtype),
                            "shape": tuple(x.shape),
                          }
                          if len(x) > 0:
                            desc = {
                              **desc,
                              "min": x.min().item(),
                              "max": x.max().item(),
                              "mean": x.mean().item(),
                              "std": x.std().item(),
                            }
                          return desc
                        else:
                          return f"{type(x)}"

                      for f in glob.glob(os.environ["checkpoint"]):
                        weights = torch.load(f, map_location="cpu")
                        del weights["optimizer"] # too much noise
                        print(f"[{f}]")
                        pprint(describe(weights))
                      EOF
                    '');
            })
          ];
        };
      in
      m.config;
    examples.butterfly = {
      cid = "QmRraDEsr3SEL2pubiqfvZ2KoFhmpCpTCmBE2BRb78PAPB";
      hash = "sha256-tLg+7HBXec51vgJsTFb05xR02fe9qzK6aYloIL1brc4=";
    };
    examples.horsejump-low = {
      cid = "QmR8k6jDhmFdaveqp3C7u2UaomJcQvmYbG7V5vDUne1mPL";
      hash = "sha256-j4N0/6vVtD/zXtbhSjzCaZ6Y0p40Zzl8kpJ0ci7IHA4=";
    };
    runVisualizer =
      let
        f =
          { checkpoint, dataDir, maskPath ? null }@viz-args:
          runCommand "omnimotion-viz-results"
            {
              nativeBuildInputs = [ (python.withPackages (ps: [ ps.omnimotion ])) ];
              requiredSystemFeatures = [ "require-cuda" ];
              passthru = { inherit viz-args; };
            }
            ''
              omnimotion-viz-default \
                --ckpt_path "${checkpoint}" \
                --data_dir "${dataDir}" \
                ${lib.optionalString (maskPath != null) ''--foreground_mask_path "${maskPath}"''} \
                --save_dir $out
            '';
      in
      lib.makeOverridable f;
    tests.viz-horsejump-with-butterfly-weights =
      merged.visualizations.horsejump-low.override { inherit (merged.visualizations.butterfly.viz-args) checkpoint; };
    tests.viz-butterfly = runVisualizer {
      checkpoint = "${merged.examples.butterfly.package}/model*.pth";
      dataDir = "${merged.examples.butterfly.package}";
      maskPath = "${merged.examples.butterfly.package}/mask_0.png";
    };
    tests.preprocess-sintel =
      callPackage
        ({ sintel ? some-datasets.config.datasets.mpi-sintel-training-images.package
         , dataDir ? "${sintel}/data/training/clean/alley_1"
         , raftThingsModel ? "${raft.merged.models.raft.weights.default.package}/raft-things.pth"
         }:
          runCommand "omnimotion-inputs"
            {
              nativeBuildInputs = [
                (python.withPackages (_: [
                  dino
                  omnimotion
                  raft
                ]))
              ];
              requiredSystemFeatures = [ "require-cuda" ];
            }
            ''
              # Not running because of chdir()s, etc
              # python -m omnimotion.preprocessing.main_processing --data_dir "${dataDir}"

              # https://github.com/qianqianwang68/omnimotion/blob/9576dd95477a65d65340425eb9c110853900f509/preprocessing/main_processing.py#L16-L29

              cd $TMPDIR

              mkdir data-dir/
              cp -rf "${dataDir}" data-dir/color
              chmod a+w data-dir/color

              export TORCH_HOME=${dino.merged.weights.vit_small_16_pretrain.package}/data/torch
              export TORCH_HUB=${dino.merged.weights.vit_small_16_pretrain.package}/data/torch/hub

              python -m omnimotion.preprocessing.exhaustive_raft --data_dir=data-dir/ --model="${raftThingsModel}"
              python -m omnimotion.preprocessing.extract_dino_features --data_dir data-dir/
              python -m omnimotion.preprocessing.filter_raft --data_dir data-dir/
              python -m omnimotion.preprocessing.chain_raft --data_dir data-dir/

              cp -rf data-dir $out
            '')
        { };
    tests.train-sintel =
      runCommand "model_10000.pth"
        {
          nativeBuildInputs = [
            (python.withPackages (_: [
              dino
              omnimotion
              raft
            ]))
          ];
          outputs = [ "out" "logs" ];
          requiredSystemFeatures = [ "require-cuda" ];
        }
        ''
          python -m omnimotion.train \
            --config ${omnimotion.configs}/data/omnimotion/default.txt \
            --data_dir "${tests.preprocess-sintel}"
          ls -l
          cp -rf out $out
          cp -rf logs $log
        '';
  };

  meta = with lib; {
    description = "";
    homepage = "https://github.com/qianqianwang68/omnimotion";
    license = licenses.asl20;
    maintainers = with maintainers; [ SomeoneSerge ];
    mainProgram = "omnimotion";
    platforms = platforms.all;
  };
}
