{ ... }: with builtins; let

  # Let any module add overlays or extra packages / pkgs.lib.X to the pkgs perSystem arg.
  flakeModules.pkgsArg = { self, ... }: {
    perSystem = { l, system, config, ... }:
      let overlayType = l.mkOptionType { name = "nixpkgs-overlay"; description = "nixpkgs overlay"; check = l.isFunction; merge = l.mergeOneOption; };
      in {
        options.pkgs.extraPkgs = l.mkOption { type = l.types.lazyAttrsOf l.types.package; default = { }; };
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
    file = ./optionDefs.nix;
  };
  # flakeModules.bin = { lib, ... }: {
  #   perSystem = { ... }: {
  #     options.bin = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
  #     # config.bin = config.bin;
  #   };
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
          # // { tools = extraInputs.tools.packages.${system} or { }; }
        );

      in
      {
        # _module.args.ownPkgs = ownPkgs;
        pkgs.extraPkgs = {
          tools = extraInputs.tools.packages.${system} or { };
          my-nix = ownPkgs;
        };
        expose.packages = {
          tools = extraInputs.tools.packages.${system} or { };
          my-nix = ownPkgs;
        };
      };
  };



  flakeModules.darwinPkgsLib = { ... }: {
    config.perSystem = { l, pkgs, ... }: {
      config.pkgs.extraLib.darwin = l.mkIf pkgs.stdenv.isDarwin {

        installDmg = { version, url, sha256, appname, meta }: pkgs.stdenvNoCC.mkDerivation {
          inherit version;
          meta = meta // {
            platforms = [ "aarch64-darwin" ];
          };
          src = fetchurl { inherit url sha256; };
          pname = l.slugify appname;
          nativeBuildInputs = [ pkgs.undmg ];
          buildInputs = [ pkgs.unzip ];
          unpackCmd = ''
            echo "File to unpack: $curSrc"
            mnt=$(mktemp -d -t ci-XXXXXXXXXX)

            function finish {
              echo "Detaching $mnt"
              /usr/bin/hdiutil detach $mnt -force
              rm -rf $mnt
            }
            trap finish EXIT

            echo "Attaching $mnt"
            /usr/bin/hdiutil attach -nobrowse -readonly $src -mountpoint $mnt

            echo "What's in the mount dir"?
            ls -la $mnt/

            echo "Copying contents"
            shopt -s extglob
            DEST="$PWD"
            (cd "$mnt"; cp -a !(Applications) "$DEST/")
          '';
          phases = [
            "unpackPhase"
            "installPhase"
          ];
          sourceRoot = "${appname}.app";
          installPhase = ''
            mkdir -p "$out/Applications/${appname}.app"
            cp -a ./. "$out/Applications/${appname}.app/"
          '';
        };
      };
    };
  };


in
{
  inherit flakeModules;
  imports = (attrValues flakeModules);
}
