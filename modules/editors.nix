{ config, pkgs, ... }: {
  perSystem = { pkgs, config, lib, ... }:
    let
      l = lib // builtins;

      bin = l.mapAttrs (n: pkg: "${pkg}/bin/${n}") (scripts // { inherit (pkgs) jq; });

      nuWd = "(git rev-parse --show-toplevel)";
      # TODO if attrs, then mapAttrs, but if one element, then just transform
      mkNuScripts = pkgs.lib.mapAttrs (name: text:
        let scriptFile = pkgs.writeScriptBin "${name}" ''${text}'';
        in pkgs.writeScriptBin "${name}" ''${pkgs.nushell}/bin/nu -n "${scriptFile}/bin/${name}" "$@" ''
      );
      mkNuScript = (name: text:
        let scriptFile = pkgs.writeScriptBin "${name}" ''${text}'';
        in pkgs.writeScriptBin "${name}" ''${pkgs.nushell}/bin/nu -n "${scriptFile}/bin/${name}" "$@" ''
      );

      paramScripts = {
        cvc = extraSettings: mkNuScript "cvc" ''
          let SETTINGS_FILE = "${nuWd}/.vscode/settings.json"
          let a = try { open $SETTINGS_FILE } catch { echo '{}' } | from json
          $a
        '';
      };

      nuScripts = mkNuScripts {
        # cvc = ''let SETTINGS_FILE = "${nuWd}/.vscode/settings.json"
        # 	let a = try { open $SETTINGS_FILE } catch { echo '{}' } | from json
        # 	$a
        #   # if ('${nuWd}/.vscode/settings.json' | path exists) {
        #   # 	mkdir "${nuWd}/.cache/backups"; cp $SETTINGS_FILE $"${nuWd}/.cache/backups/vscode.settings.json.bak_(date now | format date "%Y%m%d%H%M%S")"
        # 	# 	exit 0
        # 	# 	let config_pre = open $SETTINGS_FILE | from json
        # 	# 	echo $config_pre
        # 	# 	let obj1 = {name: "Alice", age: 30}
        # 	# 	let obj2 = {title: "Astronaut", age: 31, rank:3 }

        # 	# 	($obj1 | merge $obj2) | to json | save --append $SETTINGS_FILE
        #   # } else {
        #   # 	echo "File doesn't exist"
        #   # }
        # '';
      };

      wd = "$(git rev-parse --show-toplevel)";
      scripts = l.mapAttrs (n: t: pkgs.writeShellScriptBin n t) {
        configure-editors = ''
          if (code --help | grep -q "Visual Studio Code"); then
            ${bin.configure-vscode}
          fi
        '';
        configure-vscode = ''set -x
              if which code | grep -q "/bin/code"; then
                if [ -f ./Cargo.toml ]; then
                  ${bin.configure-vscode-rust}
                fi
              fi
            '';
        configure-vscode-rust = with bin; ''
          if [ `expr "$(which code)" : "/bin/code"` ]; then
              SETTINGS_PATH="${wd}/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
              ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
              NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"CARGO\" |= \"$(which cargo)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTC\" |= \"$(which rustc)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTFMT\" |= \"$(which rustfmt)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"SQLX_OFFLINE\" |= 1" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTFLAGS\" |= \"$(echo $RUSTFLAGS)\"" \
                  | ${jq} ".\"rust-analyzer.server.path\" |= \"$(which rust-analyzer)\"" \
                  | ${jq} ".\"rust-analyzer.runnables.command\" |= \"$(which cargo)\"" \
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"CARGO\" |= \"$(which cargo)\"" \
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTC\" |= \"$(which rustc)\"" \
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTFMT\" |= \"$(which rustfmt)\"" \
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"SQLX_OFFLINE\" |= 1" \
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTFLAGS\" |= \"$(echo $RUSTFLAGS)\""
              `;
              if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
                  echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
              fi
          fi
        '';
        configure-vscode-noir = with bin; ''
          if [ `expr "$(which code)" : "/bin/code"` ]; then
              SETTINGS_PATH="${wd}/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
              ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
              NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
                  | ${jq} ".\"noir.nargoPath\" |= \"$(which nargo)\"" \
                  | ${jq} ".\"noir.enableLSP\" |= true" \
              `;
              if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
                  echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
              fi
          fi'';
      };

    in
    {
      inherit bin;
      packages = scripts;
    };
}
