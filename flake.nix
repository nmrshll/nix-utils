{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs.follows = "nixpkgs"; };

  nixConfig.experimental-features = [ "flakes" "nix-command" ];
  nixConfig.allow-unsafe-native-code-during-evaluation = true;


  outputs = inputs@{ self, nixpkgs, parts }: with builtins;
    let
      dbg = o: (trace (toJSON o) o);
      dbgAttrs = attrs: (trace (attrNames attrs) attrs);
    in
    parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        ./modules/git.nix
        ./modules/editors.nix
        ./modules/cli-tools.nix
        ./modules/services.nix
      ];

      perSystem = { self', config, pkgs, lib, ... }: {
        options.bin = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
        config = {
          inherit bin;
          devShells.default = with pkgs; mkShell {
            buildInputs = attrValues (self'.packages);
          };
          # lib = utils;
        };
      };
    };
}





#   utils.lib.eachDefaultSystem
#     (system:
#     let
#     pkgs = import nixpkgs { inherit system; };
#   # wd = builtins.getEnv "REPO_ROOT";
#   # currentDir = builtins.toString ./.;
#   wd = "$(git rev-parse --show-toplevel)";
#   nuWd = "(git rev-parse --show-toplevel)";
#   sh_use_dbg = ''dbg_var() {  local var_name="$1";  if [ -n "''${!var_name}" ]; then  echo "$var_name=''${!var_name}";  else echo "DBG_VAR: $var_name is not set or is empty"; fi  }'';
#   # wd2 = (builtins.exec [ "git" "rev-parse" "--show-toplevel" ]);
#   wdname = "$(basename ${wd})";

#   bin = mapAttrs (name: pkg: "${pkg}/bin/${name}") scripts // {
#     jq = "${pkgs.jq.outPath}/bin/jq";
#     tmux = "${pkgs.tmux.outPath}/bin/tmux";
#   };

#   # TODO make configure-rust dependent on this
#   options = {
#     EDITOR = pkgs.lib.mkOption { type = pkgs.lib.types.string; default = null; };
#     rust.enable = pkgs.lib.mkOption { type = pkgs.lib.types.bool; default = false; };
#   };

#   # nix functions/utils to export via attribute `lib`
#   utils = {
#     debug = s: trace s s;
#     debugAttrs = attrs: (trace (toJSON attrs) attrs);
#     # TODO if attrs, then mapAttrs, but if one element, then just transform
#     mkScripts = pkgs.lib.mapAttrs (name: text: pkgs.writeShellScriptBin "${name}" ''${text}'');
#     mkNuScripts = pkgs.lib.mapAttrs (name: text:
#       let scriptFile = pkgs.writeScriptBin "${name}" ''${text}'';
#       in pkgs.writeScriptBin "${name}" ''${pkgs.nushell}/bin/nu -n "${scriptFile}/bin/${name}" "$@"''
#     );
#     mkNuScript = (name: text:
#       let scriptFile = pkgs.writeScriptBin "${name}" ''${text}'';
#       in pkgs.writeScriptBin "${name}" ''${pkgs.nushell}/bin/nu -n "${scriptFile}/bin/${name}" "$@"''
#     );
#   };

#   paramScripts = {
#     cvc = extraSettings: utils.mkNuScript "cvc" ''
#       let SETTINGS_FILE = "${nuWd}/.vscode/settings.json"
#       let a = try { open $SETTINGS_FILE } catch { echo '{}' } | from json
#       $a
#     '';
#   };

#   nuScripts = utils.mkNuScripts {
#     # cvc = ''let SETTINGS_FILE = "${nuWd}/.vscode/settings.json"
#     # 	let a = try { open $SETTINGS_FILE } catch { echo '{}' } | from json
#     # 	$a
#     #   # if ('${nuWd}/.vscode/settings.json' | path exists) {
#     #   # 	mkdir "${nuWd}/.cache/backups"; cp $SETTINGS_FILE $"${nuWd}/.cache/backups/vscode.settings.json.bak_(date now | format date "%Y%m%d%H%M%S")"
#     # 	# 	exit 0
#     # 	# 	let config_pre = open $SETTINGS_FILE | from json
#     # 	# 	echo $config_pre
#     # 	# 	let obj1 = {name: "Alice", age: 30}
#     # 	# 	let obj2 = {title: "Astronaut", age: 31, rank:3 }

#     # 	# 	($obj1 | merge $obj2) | to json | save --append $SETTINGS_FILE
#     #   # } else {
#     #   # 	echo "File doesn't exist"
#     #   # }
#     # '';
#   };

#   scripts = with bin; nuScripts // utils.mkScripts {
#     # rfmt = ''set -x
#     # 	if [ -f "${wd}/rustfmt.toml" ];
#     # 		then rustfmt --config-file="${wd}/rustfmt.toml" "$@"
#     # 		else rustfmt "$@"
#     # 	fi
#     # '';

#     # wd = ''echo "${wd}" '';
#     # debug = ''
#     #   local var_name="$1"
#     #   if [ -n "${!var_name}" ]; then
#     #       echo "DEBUG: $var_name='${!var_name}'"
#     #   else
#     #       echo "DEBUG: $var_name is not set or is empty"
#     #   fi
#     # '';

#     remote-name = ''
#       ${sh_use_dbg}
#       NB_REMOTES="$(git -C "${wd}" remote | wc -l | tr -d '[:space:]')"
#       if [ $NB_REMOTES -eq 1 ]; then
#         CURRENT_REMOTE="$(git -C "${wd}" remote | tr -d '[:space:]')";
#       else
#         >&2 echo "[ERROR]: no unique origin remote"; exit 1
#       fi
#       dbg_var CURRENT_REMOTE
#     '';
#     autorebase = ''set -euxo pipefail
#           # This script will automatically rebase your branch onto main, by doing:
#           #  - backup your current branch
#           #  - pull latest changes on main
#           #  - squash all of your branch into one commit
#           #  - rebase your branch on top of the latest main
#           # If you have conflicts after running it:
#           #  - for each file, fix conflicts, git-stage the file
#           #  - run `git rebase --continue`
#           #  - Now, your branch should have one more commit than main
#           ${sh_use_dbg}

#           SQUASH=''${SQUASH-false}
#           RESET_TARGET=''${RESET_TARGET-false}

#           REMOTE_NAME="$(remote-name)"
#           if ! git fetch "$REMOTE_NAME" ; then
#               >&2 echo "[ERROR]: Failed to fetch from remote '$REMOTE_NAME'";
#               exit 1
#           fi
#           MAIN_REMOTE_BRANCH=$(git -C "${wd}" symbolic-ref refs/remotes/''${REMOTE_NAME}/HEAD | sed "s@^refs/remotes/''${REMOTE_NAME}/@@")
#           WORK_BRANCH=$(git rev-parse --abbrev-ref HEAD)

#           TARGET_BRANCH=''${TARGET_BRANCH-$MAIN_REMOTE_BRANCH}
#           if [ -z "$TARGET_BRANCH" ] || [ "$TARGET_BRANCH" == "null" ]; then echo "TARGET_BRANCH can't be empty"; exit 1; fi

#           # echo "SQUASH: $SQUASH" "WORK_BRANCH: $WORK_BRANCH" "TARGET_BRANCH: $TARGET_BRANCH"
#           # exit 1

#           # check we're not on main or TARGET_BRANCH
#           if [[ "''${WORK_BRANCH}" =~ "''${MAIN_REMOTE_BRANCH}" ]]; then echo "[ERROR] Branch can't be main branch" && exit 1; fi
#           if [[ "''${WORK_BRANCH}" =~ "''${TARGET_BRANCH}" ]]; then echo "[ERROR] Branch can't be $TARGET_BRANCH" && exit 1; fi
#           # check everything committed
#           if [ -n "$(git status --porcelain)" ]; then
#               echo "[ERROR] There are uncommitted changes in working tree. Commit, then run this script again"
#               exit 1
#           fi

#           # backup work branch
#           BACKUP_BRANCH="''${WORK_BRANCH}_backup_$(date +%y%m%d%H%M)"
#           git checkout -b "''${BACKUP_BRANCH}"

#           # update target branch
#           git fetch $REMOTE_NAME
#           git checkout "''${TARGET_BRANCH}"
#           if [ "$RESET_TARGET" == "true" ];then
#             git reset --hard "$REMOTE_NAME/$TARGET_BRANCH"
#           else
#             git pull
#           fi
#           git checkout "''${WORK_BRANCH}"

#           # squash all changes of my branch
#           if [ "$SQUASH" == "true" ];then
#             TITLE_OF_FIRST_COMMIT_REBASED=$(git log --format=%B $(git merge-base $TARGET_BRANCH $WORK_BRANCH)..$WORK_BRANCH | tr -s '\n' | tail -n 1)
#             LAST_COMMON_COMMIT=$(git merge-base ''${WORK_BRANCH} ''${TARGET_BRANCH})
#             git reset --soft ''${LAST_COMMON_COMMIT}
#             git commit --all -m "$TITLE_OF_FIRST_COMMIT_REBASED"
#           fi

#           git rebase "''${TARGET_BRANCH}"
#         '';
#     gupdate = ''set -x
#           REPO_PATH=$(git rev-parse --show-toplevel)
#           REMOTE_NAME=$(
#             NB_REMOTES=$(git -C "$REPO_PATH" remote | wc -l | tr -d '[:space:]')
#             if [ $NB_REMOTES -eq 1 ]; then
#               CURRENT_REMOTE=$(git -C "$REPO_PATH" remote | tr -d '[:space:]'); echo $CURRENT_REMOTE
#             else
#               >&2 echo "[ERROR]: no unique origin remote"; exit 1
#             fi;
#           );
#           if ! git fetch "$REMOTE_NAME" ; then
#               >&2 echo "[ERROR]: Failed to fetch from remote '$REMOTE_NAME'";
#               exit 1
#           fi
#           MAIN_REMOTE_BRANCH=$(git -C "$REPO_PATH" symbolic-ref refs/remotes/''${REMOTE_NAME}/HEAD | sed "s@^refs/remotes/''${REMOTE_NAME}/@@")
#           WORK_BRANCH=$(git rev-parse --abbrev-ref HEAD)


#           echo "$REMOTE_NAME $MAIN_REMOTE_BRANCH $WORK_BRANCH"

#           # check we're not on main
#           if [[ "''${WORK_BRANCH}" =~ "''${MAIN_REMOTE_BRANCH}" ]]; then echo "[ERROR] Branch can't be main branch" && exit 1; fi
#           # check everything committed
#           if [ -n "$(git status --porcelain)" ]; then
#               echo "[ERROR] There are uncommitted changes in working tree. Commit, then run this script again"
#               exit 1
#           fi

#           # backup work branch
#           BACKUP_BRANCH="''${WORK_BRANCH}_backup_$(date +%y%m%d%H%M)"
#           git checkout -b "''${BACKUP_BRANCH}"
#           git checkout "''${WORK_BRANCH}"

#           git fetch "$REMOTE_NAME"
#           git merge --no-edit "$REMOTE_NAME/$MAIN_REMOTE_BRANCH" || exit 1
#         '';

#     configure-editors = ''
#       if (code --help | grep -q "Visual Studio Code"); then
#         ${bin.configure-vscode}
#       fi
#     '';
#     configure-vscode = ''set -x
#           if which code | grep -q "/bin/code"; then
#             if [ -f ./Cargo.toml ]; then
#               ${bin.configure-vscode-rust}
#             fi
#           fi
#         '';
#     configure-vscode-rust = ''
#       if [ `expr "$(which code)" : "/bin/code"` ]; then
#           SETTINGS_PATH="${wd}/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
#           ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
#           NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
#               | ${jq} ".\"rust-analyzer.server.extraEnv\".\"CARGO\" |= \"$(which cargo)\"" \
#               | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTC\" |= \"$(which rustc)\"" \
#               | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTFMT\" |= \"$(which rustfmt)\"" \
#               | ${jq} ".\"rust-analyzer.server.extraEnv\".\"SQLX_OFFLINE\" |= 1" \
#               | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTFLAGS\" |= \"$(echo $RUSTFLAGS)\"" \
#               | ${jq} ".\"rust-analyzer.server.path\" |= \"$(which rust-analyzer)\"" \
#               | ${jq} ".\"rust-analyzer.runnables.command\" |= \"$(which cargo)\"" \
#               | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"CARGO\" |= \"$(which cargo)\"" \
#               | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTC\" |= \"$(which rustc)\"" \
#               | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTFMT\" |= \"$(which rustfmt)\"" \
#               | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"SQLX_OFFLINE\" |= 1" \
#               | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"RUSTFLAGS\" |= \"$(echo $RUSTFLAGS)\""
#           `;
#           if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
#               echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
#           fi
#       fi
#     '';
#     configure-vscode-noir = ''
#       if [ `expr "$(which code)" : "/bin/code"` ]; then
#           SETTINGS_PATH="${wd}/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
#           ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
#           NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
#               | ${jq} ".\"noir.nargoPath\" |= \"$(which nargo)\"" \
#               | ${jq} ".\"noir.enableLSP\" |= true" \
#           `;
#           if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
#               echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
#           fi
#       fi'';

#     git-unsee = ''
#       # git add --intent-to-add "$@"
#       git update-index --assume-unchanged "$@"
#     '';

#     fix-fmt = ''
#       cargo fmt --all --
#       cargo clippy --fix
#     '';
#     check = ''
#       cargo fmt --all -- --check
#       cargo clippy -- -D warnings
#     '';
#     # reload-nix = writeScriptBin "reload-nix" ''
#     #   nix flake lock --update-input scriptUtils && direnv allow
#     # '';
#     dotenv = ''#!/usr/bin/env bash
#           WD=${wd}
#           if [ -f "$WD/.env" ]; then
#               source "$WD/.env";
#               case "$(uname -s)" in
#                   Linux*)     export $(grep -v '^#' .env | xargs) ;;
#                   Darwin*)    export `cat "$WD/.env" | grep -v -e '^#' -e '^[[:space:]]*$' | cut -d= -f1` ;;
#               esac
#           fi
#         '';
#     setdotenv = ''
#       if [ -f "${wd}/.env" ] && [ ! -L "${wd}/.env" ]; then
#         mkdir -p "${wd}/infra"; mv "${wd}/.env" "${wd}/infra/.env.bak.$(date +%Y%m%d%H%M%S)"
#       fi
#       case "$1" in
#         "local"*)       ln -sf "${wd}/infra/local.env" "${wd}/.env" ;;
#         "remote-dev"*)  ln -sf "${wd}/infra/remote-dev.env" "${wd}/.env" ;;
#         "devnet"*)     ln -sf "${wd}/infra/devnet.env" "${wd}/.env" ;;
#         "testnet"*)     ln -sf "${wd}/infra/testnet.env" "${wd}/.env" ;;
#         "uat"*)         ln -sf "${wd}/infra/uat.env" "${wd}/.env" ;;
#         "none"*)        rm "${wd}/.env" ;;

#         *) echo "$1 is not a supported environment. Environments supported are [\"none\", \"local\", \"remote-dev\", \"uat\"]" >&2; exit 1
#       esac
#     '';


#     sql-migrate-and-export = ''deps; await_postgres $POSTGRES_PORT; sqlx migrate run; cargo sqlx prepare; '';
#     # await_postgres_up = writeScriptBin "await_postgres_up" ''#!/usr/bin/env bash
#     #   PORT="''${1:-''${POSTGRES_PORT:-5432}}"
#     #   while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;
#     # '';
#     await_postgres = ''#!/usr/bin/env bash
#           PORT="''${1:-''${POSTGRES_PORT:-5432}}"
#           # while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;

#           # TEST STRING NOT EMPTY i.e. while not contains "accepting"
#           while ! [ -n "`${pkgs.postgresql_15}/bin/pg_isready -h 0.0.0.0 -p $PORT | grep "accepting"`" ]; do
#             echo "waiting on postgres (port $PORT)..."; sleep 0.3;
#           done
#         '';
#     await_postgres_migrated = ''#!/usr/bin/env bash
#           await_postgres
#           while test ! "sqlx migrate info | grep -q 'pending'"; do
#             echo "waiting on postgres migrations..."; sleep 0.3;
#           done
#         '';
#     await_server = ''
#       if [ -n "$1" ] || [ -n "$SERVER_ORIGIN" ]; then
#         SERVER_ORIGIN="''${1:-$SERVER_ORIGIN}"
#       else
#         echo "Error: neither argument $1 nor SERVER_ORIGIN set" >&2
#         return 1
#       fi

#       while [[ ! `curl "$SERVER_ORIGIN/health" 2>/dev/null` =~ "ok" ]]; do echo "waiting on server ($SERVER_ORIGIN)..."; sleep 0.3; done
#     '';
#     down = ''#!/usr/bin/env bash
#           docker-compose -f infra/docker-compose.yml down
#           docker network ls --filter "type=custom" --filter="name=`${wdname}`" -q | xargs -r docker network rm
#           docker ps --filter="name=`${wdname}`" -aq | xargs -r docker rm -f -v
#         '';
#     logs = ''
#       docker-compose -f infra/docker-compose.yml logs -f "$1"
#     '';

#     respawn_tmux = ''#!/usr/bin/env bash
#           ${tmux} kill-session -t session 2>/dev/null
#           ${tmux} new-session -d -s session
#           ${tmux} set-option -g remain-on-exit on
#           ${tmux} bind-key C-d kill-server # use Ctrl-b-d to kill all of tmux
#         '';
#     tmux_cmd = ''#!/usr/bin/env bash
#           SESSION="$1"
#           shift; CMD="$@"
#           if ${tmux} list-windows |grep $SESSION;
#               then ${tmux} split-window -h -t session:$SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER ;
#               else ${tmux} new-window -n $SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER;
#           fi
#         '';
#     tmux_attach = ''${tmux} attach'';
#     mux = ''
#       ${respawn_tmux};
#       while [[ $# -gt 1 ]]; do
#         window_name="$1"; cmd="$2"; shift 2
#         tmux_cmd "$window_name" "$cmd"
#       done
#       ${tmux_attach}
#     '';

#     docker-build = ''nix build .#docker; docker load < result;'';
#   };

#   packages = with pkgs; with bin; scripts // {
#     # wd = writeScriptBin "wd" ''git rev-parse --show-toplevel'';
#     # wdname = writeScriptBin "wdname" ''basename ${wd}'';
#   };

#   in
#   {
#   packages = scripts;
#   binaries = bin;
#   lib = utils // { inherit paramScripts; };

#   devShells.default = with pkgs; mkShell {
#     buildInputs = attrValues (packages // scripts);
#   };
# }
# );
# }
