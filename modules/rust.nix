{ config, pkgs, ... }: {
  perSystem = { pkgs, config, lib, ... }:
    let
      l = lib // builtins;

      bin = l.mapAttrs (n: pkg: "${pkg}/bin/${n}") { inherit (pkgs); };
      scripts = l.mapAttrs (n: t: pkgs.writeShellScriptBin n t) {
        fix-fmt = ''
          cargo fmt --all --
          cargo clippy --fix
        '';
        check = ''
          cargo fmt --all -- --check
          cargo clippy -- -D warnings
        '';

        # rfmt = ''set -x
        # 	if [ -f "${wd}/rustfmt.toml" ];
        # 		then rustfmt --config-file="${wd}/rustfmt.toml" "$@"
        # 		else rustfmt "$@"
        # 	fi
        # '';
      };

    in
    {
      inherit bin;
      packages = scripts;
    };
}
