{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: with builtins; utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      binaries = {
        jq = "${pkgs.jq.outPath}/bin/jq";
        tmux = "${pkgs.tmux.outPath}/bin/tmux";

        wd = "${packages.wd}/bin/wd";
        wdname = "${packages.wdname}/bin/wdname";
        respawn_tmux = "${packages.respawn_tmux}/bin/respawn_tmux";
        tmux_attach = "${packages.tmux_attach}/bin/tmuxa";
        configure-vscode-rust = "${packages.configure-vscode.rust}/bin/configure-vscode-rust";
        configure-vscode-noir = "${scripts.configure-vscode-noir}/bin/configure-vscode-noir";
        dotenv = "${packages.dotenv}/bin/dotenv";
      };

      # TODO make configure-rust dependent on this
      options = {
        EDITOR = pkgs.lib.mkOption { type = pkgs.lib.types.string; default = null; };
        rust.enable = pkgs.lib.mkOption { type = pkgs.lib.types.bool; default = false; };
      };

      # TODO expose mkScripts via lib
      scripts = with binaries; pkgs.lib.mapAttrs (name: value: pkgs.writeShellScriptBin "${name}" ''${value}'') {
        configure-vscode-noir = ''        
          if [ `expr "$(which code)" : "/bin/code"` ]; then 
              SETTINGS_PATH="`${wd}`/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
              ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
              NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
                  | ${jq} ".\"noir.nargoPath\" |= \"$(which nargo)\"" \
                  | ${jq} ".\"noir.enableLSP\" |= true" \
              `;
              if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
                  echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
              fi
          fi'';
        autorebase = ''#!/usr/bin/env bash
          set -euxo pipefail

          # This script will automatically rebase your branch onto main, by doing:
          #  - backup your current branch
          #  - pull latest changes on main
          #  - squash all of your branch into one commit
          #  - rebase your branch on top of the latest main
          # If you have conflicts after running it:
          #  - for each file, fix conflicts, git-stage the file
          #  - run `git rebase --continue`
          #  - Now, your branch should have one more commit than main

          REPO_PATH=$(git rev-parse --show-toplevel)
          REMOTE_NAME=$(
            NB_REMOTES=$(git -C "$REPO_PATH" remote | wc -l | tr -d '[:space:]')
            if [ $NB_REMOTES -eq 1 ]; then
              CURRENT_REMOTE=$(git -C "$REPO_PATH" remote | tr -d '[:space:]'); echo $CURRENT_REMOTE
            else
              >&2 echo "[ERROR]: no unique origin remote"; exit 1
            fi;
          );
          if ! git fetch "$REMOTE_NAME" ; then
              >&2 echo "[ERROR]: Failed to fetch from remote '$REMOTE_NAME'"; 
              exit 1
          fi
          MAIN_BRANCH=$(git -C "$REPO_PATH" symbolic-ref refs/remotes/''${REMOTE_NAME}/HEAD | sed "s@^refs/remotes/''${REMOTE_NAME}/@@")
          WORK_BRANCH=$(git rev-parse --abbrev-ref HEAD)

          TITLE_OF_FIRST_COMMIT_REBASED=$(git log --format=%B -n 1 $(git merge-base $MAIN_BRANCH $WORK_BRANCH)..$WORK_BRANCH)

          # check we're not on main
          if [[ "''${WORK_BRANCH}" =~ "''${MAIN_BRANCH}" ]]; then echo "[ERROR] Branch can't be main branch" && exit 1; fi
          # check everything committed
          if [ -n "$(git status --porcelain)" ]; then
              echo "[ERROR] There are uncommitted changes in working tree. Commit, then run this script again"
              exit 1
          fi

          # backup work branch
          BACKUP_BRANCH="''${WORK_BRANCH}_backup_$(date +%y%m%d%H%M)"
          git checkout -b "''${BACKUP_BRANCH}"

          # update main branch
          git checkout "''${MAIN_BRANCH}"
          git pull
          git checkout "''${WORK_BRANCH}"

          # squash all changes of my branch
          LAST_COMMON_COMMIT=$(git merge-base ''${WORK_BRANCH} ''${MAIN_BRANCH})
          git reset --soft ''${LAST_COMMON_COMMIT}
          git commit --all -m "$TITLE_OF_FIRST_COMMIT_REBASED"

          git rebase "''${MAIN_BRANCH}"
        '';
      };

      packages = with pkgs; with binaries; scripts // {
        wd = writeScriptBin "wd" ''git rev-parse --show-toplevel'';
        wdname = writeScriptBin "wdname" ''basename `${wd}`'';

        configure-vscode-rust = writeScriptBin "configure-vscode-rust" ''
          if [ `expr "$(which code)" : "/bin/code"` ]; then 
              SETTINGS_PATH="`${wd}`/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
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


        git-unsee = writeScriptBin "git-unsee" ''
          # git add --intent-to-add "$@"
          git update-index --assume-unchanged "$@"
        '';

        fix-fmt = writeScriptBin "fix-fmt" ''
          cargo fmt --all --
          cargo clippy --fix
        '';
        check = writeScriptBin "check" ''
          cargo fmt --all -- --check
          cargo clippy -- -D warnings
        '';
        # reload-nix = writeScriptBin "reload-nix" ''
        #   nix flake lock --update-input scriptUtils && direnv allow
        # '';
        dotenv = writeScriptBin "dotenv" ''#!/usr/bin/env bash
          WD=`${wd}`
          if [ -f "$WD/.env" ]; then 
              source "$WD/.env"; 
              case "$(uname -s)" in
                  Linux*)     export $(grep -v '^#' .env | xargs) ;;
                  Darwin*)    export `cat "$WD/.env" | grep -v -e '^#' -e '^[[:space:]]*$' | cut -d= -f1` ;;
              esac
          fi
        '';
        setenv = writeScriptBin "setenv" ''
          case "$1" in 
            "local"*)       ln -sf "`${wd}`/infra/local.env" "`${wd}`/.env" ;;
            "remote-dev"*)  ln -sf "`${wd}`/infra/remote-dev.env" "`${wd}`/.env" ;;
            "uat"*)         ln -sf "`${wd}`/infra/uat.env" "`${wd}`/.env" ;;
            "none"*)        rm "`${wd}`/.env" ;;
            
            *) echo "$1 is not a supported environment. Environments supported are [\"none\", \"local\", \"remote-dev\", \"uat\"]" >&2; exit 1
          esac
        '';


        sql-migrate-and-export = writeScriptBin "migrate" ''deps; await_postgres $POSTGRES_PORT; sqlx migrate run; cargo sqlx prepare; '';
        # await_postgres_up = writeScriptBin "await_postgres_up" ''#!/usr/bin/env bash
        #   PORT="''${1:-''${POSTGRES_PORT:-5432}}"
        #   while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;
        # '';
        await_postgres = writeScriptBin "await_postgres" ''#!/usr/bin/env bash
          PORT="''${1:-''${POSTGRES_PORT:-5432}}"
          # while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;

          # TEST STRING NOT EMPTY i.e. while not contains "accepting"
          while ! [ -n "`${pkgs.postgresql_15}/bin/pg_isready -h 0.0.0.0 -p $PORT | grep "accepting"`" ]; do
            echo "waiting on postgres (port $PORT)..."; sleep 0.3;
          done
        '';
        await_postgres_migrated = writeScriptBin "await_postgres_migrated" ''#!/usr/bin/env bash
          await_postgres
          while test ! "sqlx migrate info | grep -q 'pending'"; do
            echo "waiting on postgres migrations..."; sleep 0.3;
          done
        '';
        await_server = writeScriptBin "await_server" ''
          if [ -n "$1" ] || [ -n "$SERVER_ORIGIN" ]; then
            SERVER_ORIGIN="''${1:-$SERVER_ORIGIN}"
          else
            echo "Error: neither argument $1 nor SERVER_ORIGIN set" >&2
            return 1
          fi

          while [[ ! `curl "$SERVER_ORIGIN/health" 2>/dev/null` =~ "ok" ]]; do echo "waiting on server ($SERVER_ORIGIN)..."; sleep 0.3; done
        '';
        down = writeScriptBin "down" ''#!/usr/bin/env bash          
          docker-compose -f infra/docker-compose.yml down
          docker network ls --filter "type=custom" --filter="name=`${wdname}`" -q | xargs -r docker network rm
          docker ps --filter="name=`${wdname}`" -aq | xargs -r docker rm -f -v
        '';
        logs = writeScriptBin "logs" ''
          docker-compose -f infra/docker-compose.yml logs -f "$1"
        '';

        respawn_tmux = writeScriptBin "respawn_tmux" ''#!/usr/bin/env bash
          ${tmux} kill-session -t session 2>/dev/null
          ${tmux} new-session -d -s session
          ${tmux} set-option -g remain-on-exit on
          ${tmux} bind-key C-d kill-server # use Ctrl-b-d to kill all of tmux
        '';
        tmux_cmd = writeScriptBin "tmux_cmd" ''#!/usr/bin/env bash
          SESSION="$1"
          shift; CMD="$@"
          if ${tmux} list-windows |grep $SESSION; 
              then ${tmux} split-window -h -t session:$SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER ; 
              else ${tmux} new-window -n $SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER; 
          fi
        '';
        tmux_attach = writeScriptBin "tmuxa" ''${tmux} attach'';
        mux = writeScriptBin "mux" ''
          ${respawn_tmux};
          while [[ $# -gt 1 ]]; do
            window_name="$1"; cmd="$2"; shift 2
            tmux_cmd "$window_name" "$cmd"
          done
          ${tmux_attach}
        '';

        docker-build = writeScriptBin "mkdocker" ''nix build .#docker; docker load < result;'';
      };

    in
    {
      inherit packages binaries;
    }
  );
}
