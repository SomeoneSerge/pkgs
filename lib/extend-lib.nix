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
                module = lib.evalModules {
                  specialArgs = {
                    inherit (inputs) dream2nix;
                    packageSets.nixpkgs = ps;
                  };
                  modules = [
                    directory
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
              if kind == "package" then package else module
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
