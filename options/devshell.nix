# { lib, pkgs, ... }: {
#   perSystem = { lib, pkgs, config, ... }: {
#     options = {
#       devShellParts = {
#         buildInputs = lib.mkOption {
#           type = lib.types.listOf lib.types.package;
#           default = [ ];
#           description = "Packages to add to the dev shell environment.";
#         };
#         shellHook = lib.mkOption {
#           type = lib.types.lines;
#           default = "";
#           description = "Lines to add to the shell hook script.";
#         };
#       };
#     };
#     config.devShells.default = lib.mkDefault (pkgs.mkShell {
#       buildInputs = config.devShellParts.buildInputs;
#       shellHook = config.devShellParts.shellHook;
#     });
#   };
# }
