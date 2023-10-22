{ inputs, oldLib }:
let
  diff =
    {
      maintainers.SomeoneSerge = {
        email = "sergei.kozlukov@aalto.fi";
        matrix = "@ss:someonex.net";
        github = "SomeoneSerge";
        githubId = 9720532;
        name = "Sergei K";
      };

      readByName = import ../read-by-name.nix { lib = oldLib; };

      autocallByName = ps: baseDirectory:
        let
          files = lib.readByName baseDirectory;
          packages = oldLib.mapAttrs
            (name: { directory, kind, path }:
              let
                evaluatedModules = lib.evalModules {
                  specialArgs = {
                    inherit (inputs) dream2nix;
                    packageSets.nixpkgs = ps;
                  };
                  modules = [
                    path
                    {
                      paths.projectRoot = baseDirectory;
                      paths.projectRootFile = "flake.nix";
                      paths.package = directory;
                      paths.lockFile = "lock.json";
                    }
                  ];
                };
                package = ps.callPackage path { };
              in
              if kind == "package" then package
              else if kind == "dream2nix" then evaluatedModules.config.public
              else throw "autocallByName: unknown kind ${kind}"
            )
            files;
        in
        packages;
    };
  lib = oldLib.recursiveUpdate oldLib diff;
in
{
  inherit diff lib;
}
