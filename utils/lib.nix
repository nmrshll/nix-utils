with builtins; let

  mkLib = { lib }: rec {
    dbgJSON = o: (trace (toJSON o) o);
    dbgAttrs = o: (trace (attrNames o) o);
    # fmt = v:
    #   if isFunction v then "<function>"
    #   else if isAttrs v then mapAttrs (_: fmt) v
    #   else if isList v then map fmt v
    #   else if isPath v then "${toString v}"
    #   else v;
    # dbg = x: trace (fmt x) x;

    # fmtDepth = d: v:
    #   if d < 0 then "..."  # Stop here if we've gone too deep
    #   else if isFunction v then lib.generators.toPretty { } v
    #   else if isAttrs v then mapAttrs (_: fmtDepth (d - 1)) v
    #   else if isList v then map (fmtDepth (d - 1)) v
    #   else if isPath v then "${toString v}"
    #   else v;
    # dbg2 = x: trace (fmtDepth 4 x) x;

    dbg2 = o: (lib.traceSeqN 2 o) o;
    dbg3 = o: (lib.traceSeqN 3 o) o;
    dbg4 = o: (lib.traceSeqN 4 o) o;
    dbg5 = o: (lib.traceSeqN 5 o) o;

    # traceSeqN = depth: x: y:
    #   let
    #     snip = v:
    #       if isList v then noQuotes "[…]" v
    #       else if isAttrs v then noQuotes "{…}" v
    #       else v;
    #     noQuotes = str: v: {
    #       __pretty = lib.const str;
    #       val = v;
    #     };
    #     modify = n: fn: v:
    #       if (n == 0) then fn v
    #       else if isList v then map (modify (n - 1) fn) v
    #       else if isAttrs v then mapAttrs (lib.const (modify (n - 1) fn)) v
    #       else v;
    #   in
    #   trace (lib.generators.toPretty { allowPrettyValues = true; } (modify depth snip x)) y;


    # TODO use mapAttrs ??
    mapKeys = f: obj: listToAttrs (map
      (key: {
        name = f key;
        value = obj.${key};
      })
      (attrNames obj));
    prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;

    slugify = str: lib.toLower (replaceStrings [ " " ] [ "-" ] str);

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

  mkPkgsLib = { lib, system, ... }: {
    throwSystem = throw "Unsupported system: ${system}";
    forSystem = perSystemAttrs: perSystemAttrs.${system} or throwSystem;
  };


  flakeModules.myLib = { lib, ... }: {
    extraLib = mkLib { lib = lib; };
    perSystem = { system, lib, ... }: {
      extraLib = mkLib { lib = lib; };
      pkgs.extraLib = mkPkgsLib { inherit system; lib = lib; };
    };
  };


in
{
  flakeModules.utils = flakeModules;
  imports = (attrValues flakeModules);
}

