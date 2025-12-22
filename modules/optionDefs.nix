with builtins; let
  dbg = x: trace (toJSON x) x;

  # flakeModules.example1 = { withSystem, ... }: {
  #   # flake.nixosModules.default = { pkgs, ... }: {
  #   #   imports = [ ./nixos-module.nix ];
  #   #   services.foo.package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
  #   #     config.packages.default
  #   #   );
  #   # };
  # };

  # flakeModules.use = { lib, config, ... }: {
  #   # Define the top-level `use` option for users to list their modules
  #   options.use = lib.mkOption {
  #     type = lib.types.listOf lib.types.raw;
  #     default = [ ];
  #     description = "List of modules to import after deduplication";
  #   };

  #   # config.imports = [ ];
  #   imports =
  #     let
  #       uniqueBy = f:
  #         lib.foldl' (acc: e: if lib.elem (f e) (map f acc) then acc else acc ++ [ e ]) [ ];
  #       dedupModules = modules:
  #         uniqueBy (m: if m ? _file then m._file else m) modules;
  #     in
  #     dedupModules config.use;
  # };

  flakeModules.bin = { lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
    name = "bin";
    option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; /* default = { }; */ };
    file = ./optionDefs.nix;
  };
  # flakeModules.bin = { lib, ... }: {
  #   perSystem = { ... }: {
  #     options.bin = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
  #     # config.bin = config.bin;
  #   };
  # };
  # flakeModules.lib = { lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
  #   name = "lib";
  #   option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
  #   file = ./optionDefs.nix;
  # };
  flakeModules.lib = { lib, flake-parts-lib, config, ... }: {
    imports = [
      (flake-parts-lib.mkTransposedPerSystemModule {
        name = "lib";
        option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
        file = ./optionDefs.nix;
      })
    ];
    # _file = ./optionDefs.nix;
    # options.flake.lib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; default = { }; };
    config = {
      # lib = config.lib;
      perSystem = { lib, config, ... }: {
        # _module.args.lib = lib // config.lib;
        # _module.args.lib = { };
        # options.lib = option;
        options.lib' = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
        config = {
          _module.args.lib' = (config.lib');
          lib = config.lib';
        };
        # config.bin = config.bin;
      };
    };
  };

  # This lets any modules add overlays or extra packages to the pkgs argument.
  flakeModules.pkgs = { self, ... }: {
    perSystem = { lib, system, config, ... }:
      let
        overlayType = lib.mkOptionType {
          name = "nixpkgs-overlay";
          description = "nixpkgs overlay";
          check = lib.isFunction;
          merge = lib.mergeOneOption;
        };
      in
      {
        options.pkgs.extraPkgs = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.package; default = { }; };
        options.pkgs.overlays = lib.mkOption { type = lib.types.listOf overlayType; default = [ ]; };
        config._module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = config.pkgs.overlays; # TODO overlays for extraPkgs
          # config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          #   "terraform"
          # ];
        };
      };
  };

  # This exposes ownPkgs in flake outputs AND as a perSystem module argument (collected from pkgs/ )
  flakeModules.ownPkgs = { self, ... }: {
    perSystem = { pkgs, lib, system, config, ... }:
      let
        pkgDefs = (import ../pkgs/editor-pkgs.nix) // (import ../pkgs/service-pkgs.nix) // (import ../pkgs/gui-pkgs.nix);

        # pkgsFiles = lib.filter (name: lib.hasSuffix ".nix" name) (builtins.attrNames (builtins.readDir ../pkgs));
        # # (/. + builtins.unsafeDiscardStringContext self.outPath)
        # ownPkgDefs = lib.foldl' lib.recursiveUpdate { } (lib.map (name: import (builtins.unsafeDiscardStringContext ("../pkgs/" + name))) pkgsFiles);

        ownPkgDefs = foldl' (a: b: deepSeq b (a // b)) { } (map
          (pkgName:
            let
              pkgDef = getAttr pkgName pkgDefs;
              versionedPkgs = listToAttrs (map
                (version: {
                  name = "${pkgName}_${version}";
                  value = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib version; });
                })
                (attrNames pkgDef.versions.${system} or { }));
              defaultPkg = { ${pkgName} = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib; }); };
            in
            versionedPkgs // defaultPkg
          )
          (attrNames pkgDefs));

        ownPkgs = lib.mapAttrs (name: mkPkg: pkgs.callPackage mkPkg { }) ownPkgDefs;

      in
      {
        _module.args.ownPkgs = ownPkgs;
        packages = ownPkgs;
      };
  };


  flakeModules.devshell = { lib, pkgs, options, ... }: {
    perSystem = { lib, pkgs, config, options, ... }:
      # let
      #   shellHookParts = dbg (attrValues config.devShellParts.shellHookParts);
      #   shp_joined = dbg (lib.concatStringsSep "\n" shellHookParts);
      # in
      {
        options = {
          devShellParts = {
            buildInputs = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = (attrValues config.packages);
              description = "Packages to add to the dev shell environment.";
            };
            shellHookParts = lib.mkOption {
              type = lib.types.lazyAttrsOf (lib.types.oneOf [ lib.types.lines lib.types.str ]);
              default = { };
              description = "Named lines to add to the shell hook script.";
            };
            env = lib.mkOption {
              type = lib.types.lazyAttrsOf (lib.types.oneOf [ lib.types.str lib.types.int ]);
              default = { };
              description = "Environment variables to set in the dev shell.";
            };
          };
        };

        config.devShells.default = lib.mkDefault (pkgs.mkShell {
          env = config.devShellParts.env;
          buildInputs = config.devShellParts.buildInputs;
          shellHook = lib.concatStringsSep "\n" (attrValues config.devShellParts.shellHookParts);
        });
      };
  };

in
{
  flakeModules = flakeModules // { all = { imports = (attrValues flakeModules); }; };
}
