{ ... }: with builtins; let

  # Let any module add overlays or extra packages / pkgs.lib.X to the pkgs perSystem arg.
  flakeModules.pkgsArg = { self, ... }: {
    perSystem = { l, system, config, ... }:
      let overlayType = l.mkOptionType { name = "nixpkgs-overlay"; description = "nixpkgs overlay"; check = l.isFunction; merge = l.mergeOneOption; };
      in {
        options.pkgs.extraPkgs = l.mkOption { type = l.types.nestedAttrs l.types.package; default = { }; };
        options.pkgs.overlays = l.mkOption { type = l.types.listOf overlayType; default = [ ]; };
        # let any module add to pkgs.lib.X perSystem arg
        options.pkgs.extraLib = l.mkOption { type = l.types.nestedAttrs l.types.unspecified; default = { }; };

        config._module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = config.pkgs.overlays ++ [
            (final: prev: { lib = prev.lib // config.pkgs.extraLib; })
            (final: prev: prev // config.pkgs.extraPkgs)
          ];
          config.allowUnfree = true;
          # config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
        };
      };
  };

  # # WHY: if a flakeModule adds to "packages" output directly, then consumers of the module will also get "packages" polluted.
  # # This module lets flakeModules add packages to expose as outputs of this flake, but not consumer flakes.
  # TODO local/exposed version of all outputs
  flakeModules.exposePkgs = { self, ... }: {
    config.perSystem = { config, l, ... }: {
      options.expose.packages = l.mkOption { type = l.types.nestedAttrs l.types.package; default = { }; };
    };
  };

  flakeModules.bin = { lib, flake-parts-lib, ... }: flake-parts-lib.mkTransposedPerSystemModule {
    name = "bin";
    option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; /* default = { }; */ };
    file = ./util-options.nix;
  };
  # flakeModules.bin = { lib, ... }: {
  #   perSystem = { ... }: {
  #     options.bin = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
  #     # config.bin = config.bin;
  #   };
  # };

  # This exposes ownPkgs in flake outputs AND as a perSystem module argument (collected from pkgs/ )
  flakeModules.ownPkgs = { config, self, l, ... }: {
    options.pkgDefs = l.mkOption { type = l.types.unspecified; default = { }; };

    config.perSystem = { pkgs, l, lib, system, ... }:
      with builtins; let
        # Note: this was for collecting module files
        # TODO replace with findNixFilesRec in lib (and use from flake.nix)
        # pkgsFiles = lib.filter (name: lib.hasSuffix ".nix" name) (builtins.attrNames (builtins.readDir ../pkgs));
        # # (/. + builtins.unsafeDiscardStringContext self.outPath)
        # ownPkgDefs = lib.foldl' lib.recursiveUpdate { } (lib.map (name: import (builtins.unsafeDiscardStringContext ("../pkgs/" + name))) pkgsFiles);

        # TODO figure out env-based overrides
        mkExtraInput = overridePath: defaultSrc:
          if overridePath != "" && pathExists overridePath
          then (getFlake overridePath)
          else getFlake defaultSrc;

        extraInputs =
          let tools = mkExtraInput (getEnv "OVERRIDE_INPUT_TOOLS") "https://gitlab.com/nmrshll/tools.git";
          in {
            # TODO use PAT in URL/env for private repos
            tools = getFlake ("/Users/me/src/me/tools");
          };

        # collect packages indexed by name & version
        ownPkgDefs = foldl' (a: b: deepSeq b (a // b)) { } (map
          (pkgName:
            let
              pkgDef = getAttr pkgName config.pkgDefs;
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
          (attrNames config.pkgDefs));

        ownPkgs = l.filterAttrs (n: v: v != null) (
          (l.mapAttrs (name: mkPkg: pkgs.callPackage mkPkg { }) ownPkgDefs)
        );

      in
      {
        pkgs.extraPkgs.own = {
          tools = extraInputs.tools.packages.${system} or { };
          my-nix = ownPkgs;
        };
        expose.packages.own = {
          tools = extraInputs.tools.packages.${system} or { };
          my-nix = ownPkgs;
        };
      };
  };

  # let any module extend the flakeModule/perSystem lib arg
  flakeModules.extraLib = { config, lib, flake-parts-lib, ... }: {
    imports = [
      # TODO does this let other modules set config.lib ?? no, perSystem.config.lib ?? -> more like flake.lib.${system} ??
      (flake-parts-lib.mkTransposedPerSystemModule {
        name = "lib";
        option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
        file = ./util-options.nix;
      })
    ];

    # TODO nestedAttrs
    options.extraLib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
    config = {
      _module.args.l = config.extraLib.deepMergeSetList [ lib config.extraLib ];
    };
    # TODO find a way to merge with global libs, preferably with a namespace

    # TODO expose extraLib in flake outputs under lib
    # options.flake.lib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; default = { }; };
    # lib = config.lib;

    config.perSystem = { config, lib, pkgs, ... }: {
      # _module.args.lib = lib // config.lib;
      options.extraLib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
      config = {
        _module.args.l = config.extraLib.deepMergeSetList [ lib config.extraLib ];
      };
      # config.bin = config.bin;
    };
  };

in
{
  inherit flakeModules;
  imports = (attrValues flakeModules);
}
