{ lib, l, ... }: with builtins; let

  myLib = rec {
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
        (l.types.nestedAttrs type)
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

  mkPkgsLib = { lib, pkgs, ... }: {
    throwSystem = throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}";
    forSystem = perSystemAttrs: perSystemAttrs.${pkgs.stdenv.hostPlatform.system} or throwSystem;
  };


in
{
  extraLib = myLib;
  perSystem = { pkgs, l, ... }: {
    extraLib = myLib;
    pkgs.extraLib = mkPkgsLib { inherit pkgs; lib = l; };
  };
}
