{ lib
, buildPythonPackage
, fetchFromGitHub
, stdenv
, setuptools
, wheel
, accelerate
, basicsr
, blendmodes
, clean-fid
, codeformer
, einops
, fastapi
, gfpgan
, gitpython
, gradio
, huggingface-hub
, inflection
, jsonmerge
, k-diffusion
, kornia
, lark
, makeWrapper
, numpy
, omegaconf
, open-clip-torch
, piexif
, pillow
, prefix-python-modules
, psutil
, python
, pytorch-lightning
, realesrgan
, requests
, resize-right
, safetensors
, salesforce-blip
, scikit-image
, stability-ai-generative-models
, stability-ai-sd
, timm
, tomesd
, torch
, torchdiffeq
, torchsde
, transformers
}:

buildPythonPackage rec {
  pname = "stable-diffusion-webui";
  version = "1.6.0";
  pyproject = true;
  pyprojectToml = ./pyproject.toml;


  src = fetchFromGitHub {
    owner = "AUTOMATIC1111";
    repo = "stable-diffusion-webui";
    rev = "v${version}";
    hash = "sha256-V16VkOq0+wea4zbfeKBLAQBth022ZkpG8lh0p9u4txs=";
  };

  patches = [
    ./0001-modules.paths-try-PYTHONPATH-before-custom-search-pa.patch
  ];

  postPatch = ''
    mv extensions-builtin extensions_builtin
    find -iname '*.py' -exec sed -i \
      -e 's/extensions-builtin/extensions_builtin/g' \
      -e 's/^\([[:space:]]*\)import launch/\1import modules.launch_utils as launch/g' \
      '{}' \
      '+'

    substituteInPlace modules/paths.py \
      --replace \
        "possible_sd_paths = [" \
        "possible_sd_paths = sys.path + ["

    prefix-python-modules . --prefix sd_webui

    # Until https://github.com/python-rope/rope/issues/731
    sed -i -e '0,/import sd_webui.webui/{/import sd_webui.webui/d;}' \
      sd_webui/modules/launch_utils.py

    cp $pyprojectToml pyproject.toml
  '';

  nativeBuildInputs = [
    makeWrapper
    prefix-python-modules
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    accelerate
    basicsr
    blendmodes
    clean-fid
    codeformer
    einops
    fastapi
    gfpgan
    gitpython
    gradio
    huggingface-hub
    inflection
    jsonmerge
    k-diffusion
    kornia
    lark
    numpy
    omegaconf
    open-clip-torch
    piexif
    pillow
    psutil
    pytorch-lightning
    realesrgan
    requests
    resize-right
    safetensors
    salesforce-blip
    scikit-image
    stability-ai-generative-models
    stability-ai-sd
    timm
    tomesd
    torch
    torchdiffeq
    torchsde
    transformers
  ];

  postInstall = ''
    mkdir -p $out/bin/
    cat << EOF > $out/bin/sd-webui
    #!${stdenv.shell}
    ${lib.getExe python} -m accelerate.commands.accelerate_cli launch $out/bin/._sd-webui-launch-wrapped $@
    EOF
    chmod +x $out/bin/sd-webui
  '';

  # Circular imports...
  pythonImportsCheck = [ "sd_webui.launch" ];

  postFixup = ''
    buildPythonPath "$out $pythonPath"
    wrapProgram $out/bin/sd-webui \
      --prefix PYTHONPATH : "$program_PYTHONPATH"
  '';

  meta = with lib; {
    description = "Stable Diffusion web UI";
    homepage = "https://github.com/AUTOMATIC1111/stable-diffusion-webui";
    changelog = "https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/${src.rev}/CHANGELOG.md";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ];
  };
}
