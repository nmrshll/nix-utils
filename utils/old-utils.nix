{ pkgs, lib, ... }:
with builtins; let
  # dbgJSON = o: (trace (toJSON o) o);
  # dbgAttrs = o: (trace (attrNames o) o);
  # fmt = v:
  #   if isFunction v then "<function>"
  #   else if isAttrs v then mapAttrs (_: fmt) v
  #   else if isList v then map fmt v
  #   else if isPath v then "${toString v}"
  #   else v;
  # dbg = x: trace (fmt x) x;


  # mapKeys = f: obj:
  #   listToAttrs (
  #     map (key: { name = f key; value = obj.${key}; }) (attrNames obj)
  #   );
  # prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;
  # throwSystem = throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}";
  # forSystem = perSystemAttrs: perSystemAttrs.${pkgs.stdenv.hostPlatform.system} or throwSystem;
  # slugify = str: pkgs.lib.toLower (replaceStrings [ " " ] [ "-" ] str);

  # types = lib.types // {
  #   nestedAttrs = type: lib.types.lazyAttrsOf (lib.types.oneOf [
  #     type
  #     (lib.types.lazyAttrsOf type)
  #   ]);
  # };


  # flatMapPkgs = set:
  #   let
  #     f = p: s: builtins.foldl' (a: b: a // b) { } (builtins.attrValues (builtins.mapAttrs
  #       (k: v:
  #         if builtins.isAttrs v && !(v ? type && v.type == "derivation")
  #         then f "${p}${k}." v
  #         else { "${p}${k}" = v; }
  #       )
  #       s));
  #   in
  #   f "" set;
  # flatListPkgs = set: attrValues (flatMapPkgs set);



  # tests.flatMapPkgs = {
  #   simple = {
  #     input = { x = 1; y = 2; };
  #     expected = { x = 1; y = 2; };
  #   };
  #   nested = {
  #     input = { a = { b = 1; }; };
  #     expected = { "a.b" = 1; };
  #   };
  #   deep = {
  #     input = { x = { y = { z = 42; }; }; };
  #     expected = { "x.y.z" = 42; };
  #   };
  # };

  # runTest = name: t:
  #   let res = flatMapPkgs t.input;
  #   in assert res == t.expected ||
  #     builtins.trace "FAIL: ${name}" false;
  #   builtins.trace "PASS: ${name}" res;
  # allTests = builtins.mapAttrs runTest tests.flatMapPkgs;



in
lib // {
  inherit lib pkgs allTests;
  inherit mapKeys prefixKeys throwSystem forSystem slugify dbg dbgAttrs types flatListPkgs flatMapPkgs;
  darwin = pkgs.callPackage ./utils.darwin.nix { };
}
