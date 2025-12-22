{ pkgs, ... }:
with builtins; let
  mapKeys = f: obj:
    listToAttrs (
      map (key: { name = f key; value = obj.${key}; }) (attrNames obj)
    );
  prefixKeys = prefix: obj: mapKeys (k: "${prefix}_${k}") obj;

in
{
  shared = {
    inherit mapKeys prefixKeys;
  };
  darwin = pkgs.callPackage ./utils.darwin.nix { };
}
