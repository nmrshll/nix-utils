{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.fp.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  inputs.crane = { url = "github:ipetkov/crane"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;

  outputs = inputs@{ fp, ... }: fp.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, lib, ... }:
    with builtins; let
      utils = import ./utils/_main.nix;
      l = utils.mkLib { inherit lib; };
      # {l, utilsModules} = utils.mkLib { inherit lib; };
      utilsModules = utils.flakeModules;
      # TODO expose all utilsModules in utils
      # utilsModules = dbg (l.deepMergeSetList [
      #   (import ./utils/optionDefs.nix).flakeModules
      #   (import ./utils/lib.nix).flakeModules
      # ]);

      # NOTE: importApply injects thisFlake into module args (to distinguish from caller flake)
      flakeModules = mapAttrs (n: file: flake-parts-lib.importApply file { inherit inputs; }) {
        cli-tools = ./modules/cli-tools.nix;
        git = ./modules/git.nix;
        editors = ./modules/editors.nix;
        services = ./modules/services.nix;
        rust = ./modules/rust.nix;
      };

      # # TEMP
      # fmt = v:
      #   if isFunction v then "<function>"
      #   else if isAttrs v then mapAttrs (_: fmt) v
      #   else if isList v then map fmt v
      #   else if isPath v then "${toString v}"
      #   else v;
      # dbg = x: trace (fmt x) x;
    in
    {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [ (trace (attrNames utilsModules) utilsModules.all) ] ++ (attrValues flakeModules);

      perSystem = { pkgs, config, l, ... }: {
        packages = l.flatMapPkgs config.expose.packages;
      };

      flake.flakeModules = flakeModules // { utils = utilsModules.all; };
    });
}




