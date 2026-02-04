{ pkgs, lib, ... }:
with builtins; let
  dbgJSON = o: (trace (toJSON o) o);
  dbgAttrs = o: (trace (attrNames o) o);
  dbg = x: trace
    (
      if builtins.isAttrs x then "${builtins.toJSON x}"
      else if builtins.isList x then "${map dbg x}"
      else if builtins.isPath x then "${toString x}"
      else "${toString x}"
    )
    x;

  mapKeys = f: obj:
    listToAttrs (
      map (key: { name = f key; value = obj.${key}; }) (attrNames obj)
    );
  prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;
  throwSystem = throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}";
  forSystem = perSystemAttrs: perSystemAttrs.${pkgs.stdenv.hostPlatform.system} or throwSystem;
  slugify = str: pkgs.lib.toLower (replaceStrings [ " " ] [ "-" ] str);

  types = lib.types // {
    nestedAttrs = type: lib.types.lazyAttrsOf (lib.types.oneOf [
      type
      (lib.types.lazyAttrsOf type)
    ]);
  };



in
lib // {
  inherit lib pkgs;
  inherit mapKeys prefixKeys throwSystem forSystem slugify dbg dbgAttrs types;
  darwin = pkgs.callPackage ./utils.darwin.nix { };
}
