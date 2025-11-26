thisFlake:
{ self, config, pkgs, inputs, ... }: {
  perSystem = { pkgs, config, lib, ... }:
    with builtins; let
      dbgAttrs = o: (trace (attrNames o) o);
      l = lib // builtins;
      bin = l.mapAttrs (n: pkg: "${pkg}/bin/${n}") (scripts // { inherit (pkgs); });

      # rust-bin.beta.latest.default
      customRust = pkgs.rust-bin.beta.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" ];
        targets = [ ];
      };
      craneLib = thisFlake.inputs.crane.mkLib pkgs;

      buildInputs = [
        customRust
      ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.apple-sdk_15
        pkgs.libiconv
      ];
      devInputs = with pkgs; [
        cargo-nextest
      ];
      # src = craneLib.cleanCargoSource ./.;
      src = craneLib.cleanCargoSource self.outPath;
      relPath = p: (/. + builtins.unsafeDiscardStringContext "${self.outPath + "${p}"}");
      commonArgs = { inherit src buildInputs; strictDeps = true; };
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
      perCrateArgs = pname: {
        inherit pname cargoArtifacts;
        version = (craneLib.crateNameFromCargoToml { inherit src; }).version;
        cargoExtraArgs = "-p ${pname}";
        src = lib.fileset.toSource {
          root = (/. + builtins.unsafeDiscardStringContext self.outPath);
          fileset = lib.fileset.unions [ (craneLib.fileset.commonCargoSources (relPath "/crates/${pname}")) (relPath "/Cargo.toml") (relPath "/Cargo.lock") ];
        };
        doCheck = false; # we disable tests since we'll run them all via cargo-nextest
      };
      buildCrate = pname: craneLib.buildPackage (perCrateArgs pname);

      tests = {
        clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });
      };

      wd = "$(git rev-parse --show-toplevel)";
      scripts = l.mapAttrs (n: t: pkgs.writeShellScriptBin n t) {
        fix-fmt = ''
          cargo fmt --all --
          cargo clippy --fix
        '';
        check = ''
          cargo fmt --all -- --check
          cargo clippy -- -D warnings
        '';

        rfmt = ''set -x
        	if [ -f "${wd}/rustfmt.toml" ];
        		then rustfmt --config-file="${wd}/rustfmt.toml" "$@"
        		else rustfmt "$@"
        	fi
        '';
        cargo-newbin = ''if [ "$1" = "newbin" ]; then shift; fi; cargo new --bin "$1" --vcs none'';
        cargo-newlib = ''if [ "$1" = "newlib" ]; then shift; fi; cargo new --lib "$1" --vcs none'';

        build = ''nix build . --show-trace '';
        # run = ''cargo run $(packages) $@ '';
        run = ''cargo run $@ '';
        prun = ''cargo run -p $@ '';
        # utest = ''cargo nextest run --workspace --nocapture -- $SINGLE_TEST '';
        utest = ''set -x; cargo nextest run $(packages) --nocapture "$@" -- $SINGLE_TEST '';
        packages = ''if [ -n "$CRATE" ]; then echo "-p $CRATE"; else echo "--workspace"; fi '';
        ptest = ''package="$1"; shift; cargo nextest run -p "$package" --nocapture "$@" -- "$SINGLE_TEST" '';
        cadd = ''cargo add $(packages) $@'';
      };

      env = {
        RUST_BACKTRACE = 1;
      };

    in
    {
      inherit bin;
      packages = scripts // { inherit customRust; };
      pkgs.overlays = [ (import thisFlake.inputs.rust-overlay) ];

      devShellParts.buildInputs = buildInputs ++ devInputs ++ (attrValues scripts);
      devShellParts.env = env;
      lib' = {
        inherit craneLib;
        customRust = { inherit buildCrate; };
      };

      vscode.settings = {
        "rust-analyzer.server.extraEnv" = {
          CARGO = "${customRust}/bin/cargo";
          RUSTC = "${customRust}/bin/rustc";
          RUSTFMT = "${customRust}/bin/rustfmt";
          # SQLX_OFFLINE = 1;
          # RUSTFLAGS = env.RUST_BACKTRACE; # Assuming RUSTFLAGS refers to the RUST_BACKTRACE from the env block
        };
        "rust-analyzer.server.path" = "${customRust}/bin/rust-analyzer";
        "rust-analyzer.runnables.command" = "${customRust}/bin/cargo";
        "rust-analyzer.runnables.extraEnv" = {
          CARGO = "${customRust}/bin/cargo";
          RUSTC = "${customRust}/bin/rustc";
          RUSTFMT = "${customRust}/bin/rustfmt";
          # SQLX_OFFLINE = 1;
          # RUSTFLAGS = env.RUST_BACKTRACE; # Assuming RUSTFLAGS refers to the RUST_BACKTRACE from the env block
        };
      };
    };
}
