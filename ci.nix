# Hercules CI jobs
let
  flake = builtins.getFlake (builtins.toString ./.);
  inherit (flake) inputs;
  inherit (flake.inputs.nixpkgs-release) lib;

  branches = [ "release" "unstable" ];
  systems = [ "i686-linux" "x86_64-linux" ];
  args = {
    vanilla = { };
    cuda = {
      config.allowUnfree = true;
      config.cudaSupport = true;
      overlays = [
        (final: prev:
          let forceLocal = a: {
            preferLocalBuild = true;
            allowSubstitutes = false;
          };
          in
          {
            cudatoolkit = prev.cudatoolkit.overrideAttrs forceLocal;
            cudatoolkit_11 = prev.cudatoolkit_11.overrideAttrs forceLocal;
          })
      ];
    };
  };

  matrix = lib.cartesianProductOfSets {
    branch = branches;
    system = systems;
    argsName = lib.attrNames args;
  };

  mkName = { branch, system, argsName }:
    let
      args = args.${argsName};
      strings = [
        inputs."nixpkgs-${branch}".rev
        branch
        argsName
        system
      ];
    in
    lib.concatStringsSep "." strings;
  importOuts = { branch, system, argsName }@combination:
    let
      # pkgs = inputs."nixpkgs-${branch}".legacyPackages."${system}";
      pkgs = import inputs."nixpkgs-${branch}" (args // { inherit system; });
      outs = (pkgs.callPackage ./nur-ci.nix { }).cachePkgs;
      outs' = builtins.listToAttrs (builtins.map (out: lib.nameValuePair out.name out) outs);
    in
    lib.nameValuePair (mkName combination) (lib.recurseIntoAttrs outs');

  outsAll = lib.listToAttrs (builtins.map importOuts matrix);
in
outsAll
