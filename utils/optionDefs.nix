with builtins; let


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


  # flakeModules.lib = { lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
  #   name = "lib";
  #   option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
  #   file = ./optionDefs.nix;
  # };




  # This exposes ownPkgs in flake outputs AND as a perSystem module argument (collected from pkgs/ )
  flakeModules.ownPkgs = { self, ... }: {
    perSystem = { pkgs, l, lib, system, config, ... }:
      with builtins; let
        # pkgsFiles = lib.filter (name: lib.hasSuffix ".nix" name) (builtins.attrNames (builtins.readDir ../pkgs));
        # # (/. + builtins.unsafeDiscardStringContext self.outPath)
        # ownPkgDefs = lib.foldl' lib.recursiveUpdate { } (lib.map (name: import (builtins.unsafeDiscardStringContext ("../pkgs/" + name))) pkgsFiles);
        pkgDefs = (import ../pkgs/editor-pkgs.nix)
          // (import ../pkgs/service-pkgs.nix)
          // (import ../pkgs/gui-pkgs.nix)
          // (import ../pkgs/cli-pkgs.nix)
          // (import ../pkgs/libs-pkgs.nix);

        mkExtraInput = overridePath: defaultSrc:
          if overridePath != "" && pathExists overridePath
          then (getFlake overridePath)
          else getFlake defaultSrc;

        extraInputs =
          let
            tools = mkExtraInput (getEnv "OVERRIDE_INPUT_TOOLS") "https://gitlab.com/nmrshll/tools.git";
          in
          {
            # TODO use PAT in URL/env for private repos
            tools = getFlake ("/Users/me/src/me/tools");
          };


        # collect packages indexed by name & version
        ownPkgDefs = foldl' (a: b: deepSeq b (a // b)) { } (map
          (pkgName:
            let
              pkgDef = getAttr pkgName pkgDefs;
              versionedPkgs = listToAttrs (map
                (version: {
                  name = "${pkgName}_${version}";
                  value = { pkgs, lib, ... }: (pkgDef.mkPkg { inherit pkgs lib l version; });
                })
                (attrNames pkgDef.versions.${system} or { }));
              defaultPkg =
                if pkgDef ? versions.${system} || !(pkgDef?versions)
                then { ${pkgName} = { pkgs, lib, ... }: (pkgDef.mkPkg { inherit pkgs lib l; }); }
                else { };
            in
            versionedPkgs // defaultPkg
          )
          (attrNames pkgDefs));

        ownPkgs = lib.filterAttrs (n: v: v != null) (
          (lib.mapAttrs (name: mkPkg: pkgs.callPackage mkPkg { }) ownPkgDefs)
          // { tools = extraInputs.tools.packages.${system} or { }; }
        );

      in
      {
        _module.args.ownPkgs = ownPkgs;
        expose.packages = ownPkgs;
      };
  };


  flakeModules.devshell = { lib, pkgs, options, ... }: {
    perSystem = { lib, pkgs, config, options, ... }: {
      options = {
        devShellParts = {
          buildInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = (attrValues config.packages);
            description = "Packages to add to the dev shell environment.";
          };
          # TODO rename to shellHooks
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
{ inherit flakeModules; }

