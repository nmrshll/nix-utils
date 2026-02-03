{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.fp.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  inputs.crane = { url = "github:ipetkov/crane"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;

  outputs = inputs@{ fp, ... }: fp.lib.mkFlake { inherit inputs; } ({ flake-parts-lib, ... }:
    with builtins; let
      # dbg = o: (trace (toJSON o) o);
      # dbgAttrs = o: (trace (attrNames o) o);

      optionDefModules = (import ./modules/optionDefs.nix).flakeModules;
      flakeModules = mapAttrs (n: file: flake-parts-lib.importApply file { inherit inputs; }) {
        cli-tools = ./modules/cli-tools.nix;
        git = ./modules/git.nix;
        editors = ./modules/editors.nix;
        services = ./modules/services.nix;
        rust = ./modules/rust.nix;
      };
    in
    {
      debug = true;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [ optionDefModules.all ] ++ (attrValues flakeModules);

      perSystem = { pkgs, config, ... }: {
        packages = config.expose.packages;
        devShellParts.buildInputs = attrValues config.expose.packages;
      };

      flake.flakeModules = flakeModules // { all = optionDefModules.all; };
    });
}




