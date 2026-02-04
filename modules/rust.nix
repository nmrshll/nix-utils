thisFlake:
{ self, pkgs, inputs, ... }: {
  perSystem = { pkgs, config, l, lib, ownPkgs, ... }:
    with builtins; let
      # dbg = x: (trace x) x;

      # l = lib // builtins;
      bin = mapAttrs (n: pkg: "${pkg}/bin/${n}") (scripts // { inherit (pkgs); });

      # rust-bin.beta.latest.default
      customRust = pkgs.rust-bin.beta.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" ];
        targets = [ ];
      };
      craneLib = thisFlake.inputs.crane.mkLib pkgs;

      buildInputs = config.rust.buildInputs ++ [
        customRust
      ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.apple-sdk_15
        pkgs.libiconv
      ];
      devInputs = with pkgs; [
        cargo-nextest
      ];

      src = craneLib.cleanCargoSource self.outPath;
      relPath = p: (/. + builtins.unsafeDiscardStringContext "${self.outPath + "${p}"}");
      commonArgs = { inherit src buildInputs; strictDeps = true; };
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
      perCrateArgs = path:
        let crateToml = fromTOML (readFile (self.outPath + "/${path}/Cargo.toml"));
        in rec {
          inherit cargoArtifacts;
          pname = crateToml.package.name;
          version = crateToml.package.version;
          cargoExtraArgs = "-p ${pname}";
          src = l.fileset.toSource {
            root = (/. + builtins.unsafeDiscardStringContext self.outPath);
            fileset = l.fileset.unions [
              (craneLib.fileset.commonCargoSources (relPath "/${path}"))
              (relPath "/Cargo.toml")
              (relPath "/Cargo.lock")
            ];
          };
          doCheck = false; # we disable tests since we'll run them all via cargo-nextest
        };
      buildCrate = path: craneLib.buildPackage (perCrateArgs path);



      workspaceMembers =
        if pathExists (self.outPath + "/Cargo.toml") then (fromTOML (readFile (self.outPath + "/Cargo.toml"))).workspace.members or [ ]
        else [ ];
      expandWsMember = member:
        if l.strings.hasSuffix "/*" member then
          let
            baseDir = l.strings.removeSuffix "/*" member;
            subDirs = l.filterAttrs (name: type: type == "directory") (readDir (self.outPath + "/${baseDir}"));
          in
          map (name: "${baseDir}/${name}") (attrNames subDirs)
        else
          [ member ];

      validCratePaths = filter (crate: pathExists (relPath "/${crate}/Cargo.toml")) (concatLists (map expandWsMember workspaceMembers));
      crates = listToAttrs (map (path: { name = baseNameOf path; value = buildCrate path; }) validCratePaths);

      tests = l.optionalAttrs (pathExists (self.outPath + "/Cargo.toml")) {
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
        # cargo-wadd = ''${(l.dbg ownPkgs.tools).cargo-wadd}/bin/cargo-wadd $@'';
        cadd = ''cargo add $(packages) $@'';

        build = ''nix build . --show-trace '';
        # run = ''cargo run $(packages) $@ '';
        run = ''cargo run $@ '';
        prun = ''cargo run -p $@ '';
        # utest = ''cargo nextest run --workspace --nocapture -- $SINGLE_TEST '';
        utest = ''set -x; cargo nextest run $(packages) --nocapture "$@" -- $SINGLE_TEST '';
        packages = ''if [ -n "$CRATE" ]; then echo "-p $CRATE"; else echo "--workspace"; fi '';
        ptest = ''package="$1"; shift; cargo nextest run -p "$package" --nocapture "$@" -- "$SINGLE_TEST" '';
      };

      env = {
        RUST_BACKTRACE = "full";
      };

    in
    {
      # User input options
      options.rust.targets = l.mkOption { type = l.types.listOf l.types.str; default = [ ]; };
      options.rust.extensions = l.mkOption { type = l.types.listOf l.types.str; default = [ ]; };
      options.rust.toolchain = l.mkOption { type = l.types.package; default = customRust; };
      options.rust.buildInputs = l.mkOption { type = l.types.listOf l.types.package; default = [ ]; };
      options.rust.buildEnv = l.mkOption { type = l.types.attrs; default = { }; };
      # Internal options
      options.rust.crates = l.mkOption { type = l.types.nestedAttrs l.types.package; default = { }; };

      config = {
        inherit bin;
        rust.crates = crates;
        checks = tests;
        # legacyPackages = { inherit crates; };
        # packages = l.mapAttrs' (name: value: { name = "crate-${name}"; inherit value; }) crates;
        packages = crates;

        expose.packages = scripts // { inherit customRust; };
        pkgs.overlays = [ (import thisFlake.inputs.rust-overlay) ];

        devShellParts.buildInputs = buildInputs ++ devInputs ++ (attrValues scripts);
        devShellParts.env = env;
        l = { inherit craneLib; customRust = { inherit buildCrate; }; };

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
    };
}
