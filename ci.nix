# Hercules CI jobs
let
  flake = builtins.getFlake (builtins.toString ./.);
  inherit (flake) inputs;
  inherit (flake.inputs.nixpkgs-release) lib;

  branches = [ "release" "unstable" ];
  systems = [ "i686-linux" "x86_64-linux" ];
  configs = [
    { allowUnfree = false; }
    { allowUnfree = true; cudaSupport = true; }
  ];
  matrix = lib.cartesianProductOfSets {
    branch = branches;
    system = systems;
    config = configs;
  };
  # E.g. [] or ["unfree" "cuda"]
  cfgToStrings = c:
    lib.optional c.allowUnfree or false "unfree"
    ++ lib.optional c.cudaSupport or false "cuda";
  # E.g. "release-x86_64-linux-unfree-cuda"
  mkName = { branch, system, config }:
    let strings = [
      branch
      system
    ] ++ cfgToStrings config;
    in lib.concatStringsSep "-" strings;
  importOuts = { branch, system, config }@combination:
    let
      # pkgs = inputs."nixpkgs-${branch}".legacyPackages."${system}";
      pkgs = import inputs."nixpkgs-${branch}" { inherit system config; };
      outs = lib.recurseIntoAttrs (pkgs.callPackage ./default.nix { });
    in
    lib.nameValuePair (mkName combination) outs;
  outsAll = lib.listToAttrs (builtins.map importOuts matrix);
in
outsAll
