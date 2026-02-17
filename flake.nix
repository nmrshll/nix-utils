{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.fp.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  inputs.crane = { url = "github:ipetkov/crane"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;

  outputs = inputs@{ fp, ... }: fp.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, lib, l, ... }:
    with builtins; let

      utilsModules = [
        # (import ./utils/optionDefs.nix)
        (import ./utils/lib.nix)
        (import ./utils/pkg-utils.nix)
      ];

      # NOTE: importApply injects thisFlake into module args (to distinguish from caller flake)
      flakeModules = mapAttrs (n: file: flake-parts-lib.importApply file { inherit inputs; }) {
        cli-tools = ./modules/cli-tools.nix;
        git = ./modules/git.nix;
        editors = ./modules/editors.nix;
        services = ./modules/services.nix;
        rust = ./modules/rust.nix;
        devshell = ./modules/devshell.nix;
      };

      extraImports = [
        ({ lib, ... }: {
          options.flakeModules = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; }; # TODO nestedAttrs
        })
      ];

    in
    {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = utilsModules ++ (attrValues flakeModules) ++ extraImports;

      perSystem = { pkgs, config, l, ... }: {
        packages = l.flatMapPkgs config.expose.packages;
      };

      flake.flakeModules = flakeModules // { utils = utilsModules.all; };
    });
}




