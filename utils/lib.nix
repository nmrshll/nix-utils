with builtins; let

  mkLib = { lib, ... }: rec {
    dbgJSON = o: (trace (toJSON o) o);
    dbgAttrs = o: (trace (attrNames o) o);
    fmt = v:
      if isFunction v then "<function>"
      else if isAttrs v then mapAttrs (_: fmt) v
      else if isList v then map fmt v
      else if isPath v then "${toString v}"
      else v;
    dbg = x: trace (fmt x) x;


    # TODO use mapAttrs ??
    mapKeys = f: obj: listToAttrs (map (key: { name = f key; value = obj.${key}; }) (attrNames obj));
    prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;

    slugify = str: lib.toLower (replaceStrings [ " " ] [ "-" ] str);

    types = lib.types // {
      nestedAttrs = type: lib.types.lazyAttrsOf (lib.types.oneOf [
        type
        (lib.types.lazyAttrsOf type)
      ]);
    };

    # deepMergeSetList = foldl' lib.recursiveUpdate { };
    deepMergeSetList = listOfAttrs:
      lib.zipAttrsWith
        (name: values:
          if lib.all lib.isAttrs values then deepMergeSetList values
          else if lib.all lib.isList values then lib.concatLists values
          else lib.last values
        )
        listOfAttrs;

    flatMapPkgs = set:
      let
        f = p: s: builtins.foldl' (a: b: a // b) { } (builtins.attrValues (builtins.mapAttrs
          (k: v:
            if builtins.isAttrs v && !(v ? type && v.type == "derivation") then f "${p}${k}." v
            else { "${p}${k}" = v; }
          )
          s));
      in
      f "" set;
    flatListPkgs = set: attrValues (flatMapPkgs set);
  };

  pkgsLib = { lib, pkgs, ... }: {
    throwSystem = throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}";
    forSystem = perSystemAttrs: perSystemAttrs.${pkgs.stdenv.hostPlatform.system} or throwSystem;
  };


  flakeModules.pkgsLib = { ... }: {
    perSystem = { pkgs, l, ... }: {
      pkgs.extraLib = pkgsLib { inherit pkgs; lib = l; };
    };
  };

  # let any module extend the flakeModule/perSystem lib arg
  flakeModules.extraLib = { lib, flake-parts-lib, config, ... }:
    let localLib = mkLib { inherit lib; };
    in {
      imports = [
        # TODO does this let other modules set config.lib ?? no, perSystem.config.lib ?? -> more like flake.lib.${system} ??
        (flake-parts-lib.mkTransposedPerSystemModule {
          name = "lib";
          option = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
          file = ./optionDefs.nix;
        })
      ];

      # TODO nestedAttrs
      options.extraLib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
      config = {
        _module.args.l = localLib.deepMergeSetList [ lib localLib config.extraLib ];
      };
      # TODO find a way to merge with global libs, preferably with a namespace

      # TODO expose extraLib in flake outputs under lib
      # options.flake.lib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.str; default = { }; };
      # lib = config.lib;

      config.perSystem = { lib, config, pkgs, ... }: {
        # _module.args.lib = lib // config.lib;
        options.extraLib = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; default = { }; };
        config = {
          _module.args.l = localLib.deepMergeSetList [ lib localLib config.extraLib ];
        };
        # config.bin = config.bin;
      };
    };

in
{ inherit flakeModules; }
