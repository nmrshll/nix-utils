with builtins; let
  lib = import ./lib.nix;

  optionDefModules = (import ./optionDefs.nix).flakeModules;
  pkgModules = (import ./pkg-utils.nix).flakeModules;
  libModules = lib.flakeModules;

  allFlakeModules = optionDefModules // libModules // pkgModules;

in
{
  inherit (lib) mkLib;
  flakeModules = allFlakeModules // { all.imports = (attrValues allFlakeModules); };
}
