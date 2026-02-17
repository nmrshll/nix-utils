{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.fp.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  inputs.crane = { url = "github:ipetkov/crane"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;

  outputs = inputs@{ fp, ... }: fp.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, lib, l, ... }:
    with builtins; let

      # NOTE: importApply injects thisFlake into module args (to distinguish from caller flake)
      flakeModules = mapAttrs (n: file: flake-parts-lib.importApply file { inherit inputs; }) {
        cli-tools = ./modules/cli-tools.nix;
        git = ./modules/git.nix;
        editors = ./modules/editors.nix;
        services = ./modules/services.nix;
        rust = ./modules/rust.nix;
        devshell = ./modules/devshell.nix;
      };
      pkgModules = [
        (import ./pkgs/cli-pkgs.nix)
        (import ./pkgs/editor-pkgs.nix)
        (import ./pkgs/gui-pkgs.nix)
        (import ./pkgs/libs-pkgs.nix)
        (import ./pkgs/service-pkgs.nix)
      ];
      utilsModules = [
        (import ./utils/lib.nix)
        (import ./utils/util-options.nix)
        (import ./utils/lib.darwin.nix)
      ];

      extraImports = [
        ({ l, ... }: {
          options.flakeModules = lib.mkOption { type = lib.types.nestedAttrs lib.types.unspecified; };
        })
      ];

    in
    {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = (attrValues flakeModules) ++ pkgModules ++ utilsModules ++ extraImports;

      perSystem = { pkgs, config, l, ... }: {
        packages = l.flatMapPkgs config.expose.packages;
      };

      flake.flakeModules = flakeModules // { utils = utilsModules.all; };
    });
}




