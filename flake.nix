{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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
      };

      packages = with pkgs; with binaries; {
        wd = pkgs.writeScriptBin "wd" ''git rev-parse --show-toplevel'';
        wdname = pkgs.writeScriptBin "wdname" ''basename `${wd}`'';

        configure-vscode = pkgs.writeScriptBin "configure-vscode" ''
          if [ `expr "$(which code)" : "/bin/code"` ]; then 
              SETTINGS_PATH="`${wd}`/.vscode/settings.json"; mkdir -p $(dirname "$SETTINGS_PATH");
              ORIGINAL_SETTINGS=$(if [[ $(file --mime "$SETTINGS_PATH") =~ "application/json" ]]; then cat "$SETTINGS_PATH"; else echo "{}"; fi)
              NEW_SETTINGS=`echo "$ORIGINAL_SETTINGS" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"CARGO\" |= \"$(which cargo)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTC\" |= \"$(which rustc)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"RUSTFMT\" |= \"$(which rustfmt)\"" \
                  | ${jq} ".\"rust-analyzer.server.extraEnv\".\"SQLX_OFFLINE\" |= 1" \
                  | ${jq} ".\"rust-analyzer.server.path\" |= \"$(which rust-analyzer)\""
              `;
              if [ "$(cat $SETTINGS_PATH)" != "$NEW_SETTINGS" ]; then
                  echo "$NEW_SETTINGS" >| "$SETTINGS_PATH"
              fi
          fi
        '';
        fix-fmt = pkgs.writeScriptBin "ffix" ''
          cargo fmt --all --
          cargo clippy --fix
        '';
        check = pkgs.writeScriptBin "check" ''
          cargo fmt --all -- --check
          cargo clippy -- -D warnings
        '';
        reload-nix = pkgs.writeScriptBin "reload-nix" ''
          nix flake lock --update-input scriptUtils && direnv allow
        '';
        dotenv = pkgs.writeScriptBin "dotenv" ''#!/usr/bin/env bash
          wd=`${wd}`;
          if [ -f "$wd/.env" ]; then 
              source "$wd/.env"; 
              case "$(uname -s)" in
                  Linux*)     echo "NOT SUPPORTED YET: sourcing .env on Linux" ;; # TODO
                  Darwin*)    
                    export `cat "$wd/.env" | grep -v -e '^#' -e '^[[:space:]]*$' | cut -d= -f1` ;;
              esac
          fi
        '';


        sql-export = pkgs.writeScriptBin "sqlex" ''deps; await_postgres $POSTGRES_PORT; sqlx migrate run; cargo sqlx prepare; '';
        await_postgres_up = pkgs.writeScriptBin "await_postgres_up" ''#!/usr/bin/env bash
          PORT="''${1:-''${POSTGRES_PORT:-5432}}"
          while ! test "`echo -ne "\x00\x00\x00\x17\x00\x03\x00\x00user\x00username\x00\x00" | nc -w 3 0.0.0.0 $PORT 2>/dev/null | head -c1`" = R; do echo "waiting on postgres (port $PORT)..."; sleep 0.3; done;
        '';
        await_postgres_migrated = pkgs.writeScriptBin "await_postgres" ''#!/usr/bin/env bash
          await_postgres
          while test ! "sqlx migrate info | grep -q 'pending'"; do
            echo "waiting on postgres migrations..."; sleep 0.3;
          done
        '';
        await_server = pkgs.writeScriptBin "await_server" ''
          if [ -n "$1" ] || [ -n "$SERVER_ORIGIN" ]; then
            SERVER_ORIGIN="''${1:-$SERVER_ORIGIN}"
          else
            echo "Error: neither argument $1 nor SERVER_ORIGIN set" >&2
            return 1
          fi

          while [[ ! `curl "$SERVER_ORIGIN/health/ping" 2>/dev/null` =~ "pong" ]]; do echo "waiting on server ($SERVER_ORIGIN)..."; sleep 0.3; done
        '';
        down = pkgs.writeScriptBin "down" ''#!/usr/bin/env bash          
          docker-compose -f infra/docker-compose.yml down
          docker network ls --filter "type=custom" --filter="name=`${wdname}`" -q | xargs -r docker network rm
          docker ps --filter="name=`${wdname}`" -aq | xargs -r docker rm -f -v
        '';
        logs = pkgs.writeScriptBin "logs" ''
          docker-compose -f infra/docker-compose.yml logs -f "$1"
        '';

        respawn_tmux = pkgs.writeScriptBin "respawn_tmux" ''#!/usr/bin/env bash
          ${tmux} kill-session -t session 2>/dev/null
          ${tmux} new-session -d -s session
          ${tmux} set-option -g remain-on-exit on
          ${tmux} bind-key C-d kill-server # use Ctrl-b-d to kill all of tmux
        '';
        tmux_cmd = pkgs.writeScriptBin "tmux_cmd" ''#!/usr/bin/env bash
          SESSION="$1"
          shift; CMD="$@"
          if ${tmux} list-windows |grep $SESSION; 
              then ${tmux} split-window -h -t session:$SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER ; 
              else ${tmux} new-window -n $SESSION ';' send-keys -t session:$SESSION "''${CMD}" ENTER; 
          fi
        '';
        tmux_attach = pkgs.writeScriptBin "tmuxa" ''${tmux} attach'';
        mux = pkgs.writeScriptBin "mux" ''
          ${respawn_tmux};
          while [[ $# -gt 1 ]]; do
            window_name="$1"; cmd="$2"; shift 2
            tmux_cmd "$window_name" "$cmd"
          done
          ${tmux_attach}
        '';

        docker-build = pkgs.writeScriptBin "mkdocker" ''nix build .#docker; docker load < result;'';


      };

    in
    {
      packages = packages;
    }
  );
}
