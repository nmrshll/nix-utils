# {
#   flakeModules.bin = ({ lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
#     name = "bin";
#     option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; /* default = { }; */ };
#     file = ./flake.nix;
#   });
# }

with builtins; let
  flakeModules.bin = { lib, ... }: {
    perSystem = { ... }: {
      options = { };
    };
  };

  flakeModules.devshell = { lib, pkgs, ... }: {
    perSystem = { lib, pkgs, config, ... }: {
      options = {
        myDevShell = {
          buildInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Packages to add to the dev shell environment.";
          };
          shellHook = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Lines to add to the shell hook script.";
          };
        };
      };
      config.devShells.default = lib.mkDefault (pkgs.mkShell {
        buildInputs = config.myDevShell.buildInputs;
        shellHook = config.myDevShell.shellHook;
      });
    };
  };

in
{
  flakeModules = flakeModules // { all = { imports = [ (attrValues flakeModules) ]; }; };
}
