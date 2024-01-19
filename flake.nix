{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      binaries = {
        jq = "${pkgs.jq.outPath}/bin/jq";
        tmux = "${pkgs.tmux.outPath}/bin/tmux";

        wd = "${packages.wd}/bin/wd";
        wdname = "${packages.wdname}/bin/wdname";
        respawn_tmux = "${packages.respawn_tmux}/bin/respawn_tmux";
        tmux_attach = "${packages.tmux_attach}/bin/tmuxa";
        configure-vscode = "${packages.configure-vscode}/bin/configure-vscode";
      };

      packages = with pkgs; with binaries; {
        wd = writeScriptBin "wd" ''git rev-parse --show-toplevel'';
        wdname = writeScriptBin "wdname" ''basename `${wd}`'';

        configure-vscode = writeScriptBin "configure-vscode" ''
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
                  | ${jq} ".\"rust-analyzer.runnables.extraEnv\".\"CARGO\" |= \"${packages.vscargo}\"" \
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
        vscargo = writeScriptBin "vscargo" ''
          ${packages.dotenv} && cargo "$@"
        '';
        autorebase = writeScriptBin "autorebase" ''
          #!/usr/bin/env bash
          set -euxo pipefail

          # This script will automatically rebase your branch on main, by doing:
          # - backup your current branch
          # - pull latest changes on main
          # - squash all of your branch into one commit
          # - rebase your branch on top of the latest main
          # After running it:
          # - if you have conflicts:
          #     - fix them in the files, then in git, stage each fixed file
          #     - once there are no more conflicts (and all files are staged)
          #     - run `git rebase --continue`
          # - Now, your branch should have one more commit than main

          # check we're not on main
          bname=`git rev-parse --abbrev-ref HEAD`
          if [[ "''${bname}" =~ "main" ]]; then echo "[ERROR] Branch can't be 'main'" && exit 1; fi
          # check everything committed
          if [ -n "$(git status --porcelain)" ]; then
              echo "[ERROR] There are uncommitted changes in working tree. Commit, then run this script again"
              exit 1
          fi

          backup_branch="''${bname}_backup_$(date +%y%m%d%H%M)"
          git checkout -b "''${backup_branch}"

          # update main
          git checkout main
          git pull
          git checkout ''${bname}

          last_common=`git merge-base ''${bname} main`

          # squash all changes of my branch
          git reset --soft ''${last_common}
          git commit --all -m "squash all ''${bname}"

          git rebase main
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
          set -euxo pipefail
          WD=`${wd}`
          if [ -f "$WD/.env" ]; then 
              source "$WD/.env"; 
              case "$(uname -s)" in
                  Linux*)     echo "NOT SUPPORTED YET: sourcing .env on Linux" ;; # TODO
                  Darwin*)    
                    export `cat "$WD/.env" | grep -v -e '^#' -e '^[[:space:]]*$' | cut -d= -f1` ;;
              esac
          fi
        '';


        sql-export = writeScriptBin "sqlex" ''deps; await_postgres $POSTGRES_PORT; sqlx migrate run; cargo sqlx prepare; '';
        # await_postgres_up = writeScriptBin "await_postgres_up" ''#!/usr/bin/env bash
        #   PORT="''${1:-''${POSTGRES_PORT:-5432}}"
        #   while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;
        # '';
        # await_postgres_migrated = writeScriptBin "await_postgres" ''#!/usr/bin/env bash
        #   await_postgres
        #   while test ! "sqlx migrate info | grep -q 'pending'"; do
        #     echo "waiting on postgres migrations..."; sleep 0.3;
        #   done
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

          while [[ ! `curl "$SERVER_ORIGIN/health/ping" 2>/dev/null` =~ "pong" ]]; do echo "waiting on server ($SERVER_ORIGIN)..."; sleep 0.3; done
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
