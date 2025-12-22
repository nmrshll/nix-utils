{ pkgs, ... }:
with builtins; let
  mapKeys = f: obj:
    listToAttrs (
      map (key: { name = f key; value = obj.${key}; }) (attrNames obj)
    );
  prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;
  throwSystem = throw "Unsupported system: ${pkgs.system}";
  forSystem = perSystemAttrs: perSystemAttrs.${pkgs.system} or throwSystem;
  slugify = str: pkgs.lib.toLower (replaceStrings [ " " ] [ "-" ] str);

in
{
  inherit mapKeys prefixKeys throwSystem forSystem slugify;
  darwin = pkgs.callPackage ./utils.darwin.nix { };
}
