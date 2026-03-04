{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.fp.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  inputs.crane = { url = "github:ipetkov/crane"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;

  outputs = inputs@{ fp, ... }: fp.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, lib, ... }:
    with builtins; let
      l = (import ./utils/lib.p.nix { lib = lib; }).extraLib;

      # NOTE: importApply injects thisFlake into module args (to distinguish from caller flake)
      flakeModules = mapAttrs (n: file: flake-parts-lib.importApply file { inherit inputs; }) {
        cli-tools = ./modules/cli-tools.nix;
        git = ./modules/git.nix;
        editors = ./modules/editors.nix;
        services = ./modules/services.nix;
        rust = ./modules/rust.nix;
        devshell = ./modules/devshell.nix;
      };
      # pkgModules = [
      #   (import ./pkgs/cli-pkgs.nix)
      #   (import ./pkgs/editor-pkgs.nix)
      #   (import ./pkgs/gui-pkgs.nix)
      #   (import ./pkgs/libs-pkgs.nix)
      #   (import ./pkgs/service-pkgs.nix)
      # ];
      pkgModules = lib.flatten (map (dir: l.findNixFilesRec dir) [ ./pkgs ]);
      utilsModules = [
        (import ./utils/lib.p.nix)
        (import ./utils/util-options.p.nix)
        (import ./utils/lib.darwin.p.nix)
      ];


    in
    {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = (attrValues flakeModules) ++ pkgModules ++ utilsModules ++ [{
        options.flakeInputsOf.my-nix = l.constOpt inputs;
      }];

      perSystem = { pkgs, config, l, ... }: {
        # packages = l.flatListPkgs config.expose.packages;
      };

      flake.flakeModules = flakeModules // {
        utils.exposeInputs = { ... }: {
          options.flakeInputsOf.my-nix = l.constOpt (l.dbg2 inputs);
        };
      }; # expose to consumers
      # flake.flakeModules.utils = {
      #   options.flakeInputsOf.my-nix = l.constOpt inputs;
      # };
      # inherit flakeModules; # expose to flake-parts recursive evaluation
    });
}




