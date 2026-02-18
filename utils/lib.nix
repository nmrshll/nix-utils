with builtins; let

  mkLib = { lib }: rec {
    dbgJSON = o: (trace (toJSON o) o);
    dbgAttrs = o: (trace (attrNames o) o);

    dbg2 = o: (lib.traceSeqN 2 o) o;
    dbg3 = o: (lib.traceSeqN 3 o) o;
    dbg4 = o: (lib.traceSeqN 4 o) o;
    dbg5 = o: (lib.traceSeqN 5 o) o;


    # TODO use mapAttrs ??
    mapKeys = f: obj: listToAttrs (map
      (key: {
        name = f key;
        value = obj.${key};
      })
      (attrNames obj));
    prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;

    slugify = str: lib.toLower (replaceStrings [ " " ] [ "-" ] str);

    findNixFilesRec = dir: lib.flatten (lib.mapAttrsToList
      (name: type:
        let path = "${toString dir}/${name}"; in
        if type == "directory" then findNixFilesRec path  # Recursively call if it's a directory
        else if type == "regular" && lib.hasSuffix ".nix" name then [ path ]  # Collect the path if it's a .nix file
        else [ ]  # Ignore everything else
      )
      (builtins.readDir dir));

    types = lib.types // {
      nestedAttrs = type: lib.types.lazyAttrsOf (lib.types.oneOf [
        type
        (types.nestedAttrs type)
      ]);
    };

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

  # TODO all lib should go in here
  mkPkgsLib = { lib, pkgs ? null, system ? pkgs.hostPlatform.system, ... }: {
    throwSystem = throw "Unsupported system: ${system}";
    forSystem = perSystemAttrs: perSystemAttrs.${system} or throwSystem;
  } /* // mkLib { lib = lib; } */;


  flakeModules.myLib = { lib, ... }: {

    config.extraLib = mkLib { lib = lib; };
    config.perSystem = { system, lib, ... }: {
      extraLib = mkLib { lib = lib; };
      pkgs.extraLib = mkPkgsLib { inherit system; lib = lib; };
    };

    # usual shape of lib: fn({finalPkgs,lib}) -> {attrs}
    options.flake.lib = lib.mkOption { type = lib.types.unspecified; default = { }; };
    # config.flake.lib = final: mkPkgsLib { lib = final.lib; pkgs = final; };
    config.flake.lib = mkLib { lib = lib; };
  };


in
{
  flakeModules.utils = flakeModules;
  imports = (attrValues flakeModules);
}

