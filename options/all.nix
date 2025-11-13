# with builtins; let
#   dbg = x: trace (toJSON x) x;

#   # flakeModules.example1 = { withSystem, ... }: {
#   #   # flake.nixosModules.default = { pkgs, ... }: {
#   #   #   imports = [ ./nixos-module.nix ];
#   #   #   services.foo.package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
#   #   #     config.packages.default
#   #   #   );
#   #   # };
#   # };

#   # flakeModules.use = { lib, config, ... }: {
#   #   # Define the top-level `use` option for users to list their modules
#   #   options.use = lib.mkOption {
#   #     type = lib.types.listOf lib.types.raw;
#   #     default = [ ];
#   #     description = "List of modules to import after deduplication";
#   #   };

#   #   # config.imports = [ ];
#   #   imports =
#   #     let
#   #       uniqueBy = f:
#   #         lib.foldl' (acc: e: if lib.elem (f e) (map f acc) then acc else acc ++ [ e ]) [ ];
#   #       dedupModules = modules:
#   #         uniqueBy (m: if m ? _file then m._file else m) modules;
#   #     in
#   #     dedupModules config.use;
#   # };

#   #   flakeModules.bin = ({ lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
#   #     name = "bin";
#   #     option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; /* default = { }; */ };
#   #     file = ./flake.nix;
#   #   });
#   flakeModules.bin = { lib, ... }: {
#     perSystem = { ... }: {
#       options.bin = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
#     };
#   };

#   # lib.mkIf (dbg (hasAttr "devShellParts" options))
#   flakeModules.devshell = { lib, pkgs, options, ... }: {
#     perSystem = { lib, pkgs, config, options, ... }: {
#       options = {
#         devShellParts = {
#           buildInputs = lib.mkOption {
#             type = lib.types.listOf lib.types.package;
#             default = [ ];
#             description = "Packages to add to the dev shell environment.";
#           };
#           shellHook = lib.mkOption {
#             type = lib.types.lines;
#             default = "";
#             description = "Lines to add to the shell hook script.";
#           };
#         };
#         # devShells.default = lib.mkDefault (lib.mkOption {
#         #   type = lib.types.nullOr lib.types.package;
#         #   default = null;
#         #   description = "The default dev shell to use.";
#         # });
#       };

#       config.devShells.default = lib.mkForce (pkgs.mkShell {
#         buildInputs = config.devShellParts.buildInputs;
#         shellHook = config.devShellParts.shellHook;
#       });

#       # pkgs.mkShell
#       #   {
#       #   buildInputs = config.devShellParts.buildInputs;
#       # shellHook = config.devShellParts.shellHook;

#       # config.devShells.default = lib.mkIf (!hasAttr "fhdjsk" config.devShells) { };
#       # config.devShells.default = lib.mkIf (!elem "devShellParts" (attrNames options)) (pkgs.mkShell {
#       #   buildInputs = config.devShellParts.buildInputs;
#       #   shellHook = config.devShellParts.shellHook;
#       # });
#     };
#   };

# in
# {
#   flakeModules = flakeModules // { all = { imports = (attrValues flakeModules); }; };
# }
