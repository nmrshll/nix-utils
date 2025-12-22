with builtins; let
  # localLib = import ../utils/utils.nix { };
  # l = builtins // localLib;
  dbg = o: trace (toJSON o) o;
in
{
  # anytype =
  #   let
  #     version = "0.47.3";
  #     src = localLib.forSystem {
  #       aarch64-darwin = { url = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg"; sha256 = "sha256:1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj"; };
  #     };
  #   in
  #   localLib.installDmg {
  #     inherit (src) url sha256;
  #     inherit version;
  #     appname = "AnyType";
  #     meta = { description = "A space for your thoughts, private, local, p2p & open"; homepage = "https://anytype.io/"; };
  #   };
  anytype = rec {
    versions = {
      aarch64-darwin."0.47.3".sha256 = "sha256:1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj";
    };
    mkPkg = { pkgs, version ? "0.47.3", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // pkgs.callPackage ../utils/utils.nix { };
        url = {
          aarch64-darwin = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg";
        }.${system} or (throw "Unsupported system: ${system}");
      in
      l.darwin.installDmg (dbg {
        inherit version url;
        sha256 = versions.${system}.${version}.sha256;
        appname = "AnyType";
        meta = { description = "A space for your thoughts, private, local, p2p & open"; homepage = "https://anytype.io/"; };
      });
  };

  # beeper = { pkgs, version ? "4.0.779", system ? pkgs.stdenv.hostPlatform.system, ... }:
  #   let
  #     version = "4.0.779";
  #     appname = "Beeper";
  #     url = localLib.forSystem {
  #       # aarch64-darwin = "https://download.beeper.com/versions/${version}/mac/dmg/arm64";
  #       aarch64-darwin = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-arm64-mac.zip";
  #       x86_64-linux = "https://download.beeper.com/versions/${version}/linux/appImage/x64";
  #     };
  #     src = localLib.forSystem {
  #       aarch64-darwin = { inherit url; sha = "sha256:1z9z5aswx1fh2z8pd5761z4db6q8z4mbl4vshfh5wy055l0gvvp4"; };
  #     };
  #   in
  #   pkgs.stdenvNoCC.mkDerivation {
  #     inherit version;
  #     meta = { description = "All your chats in one app"; homepage = "https://beeper.com"; };
  #     src = builtins.fetchurl { inherit url; sha256 = src.sha; };
  #     pname = localLib.slugify appname;
  #     nativeBuildInputs = [ pkgs.undmg ];
  #     buildInputs = [ pkgs.unzip ];
  #     unpackCmd = ''set -x
  #           echo "File to unpack: $curSrc"
  #           if ! [[ "$curSrc" =~ \.zip$ ]]; then echo "[ERROR] Expected a zip file"; return 1; fi
  #           runHook preUnpack
  #           echo "Unzipping $src to $PWD"
  #           unzip $src
  #           runHook postUnpack
  #         '';
  #     phases = [
  #       "unpackPhase"
  #       "installPhase"
  #     ];
  #     # sourceRoot = "${appname}.app";
  #     installPhase = ''
  #       mkdir -p "$out/Applications/${appname}.app"
  #       cp -a ./. "$out/Applications/${appname}.app/"
  #     '';
  #   };
  beeper = rec {
    versions = {
      aarch64-darwin."4.0.779".sha256 = "sha256:1z9z5aswx1fh2z8pd5761z4db6q8z4mbl4vshfh5wy055l0gvvp4";
    };
    mkPkg = { pkgs, version ? "4.0.779", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // (pkgs.callPackage ../utils/utils.nix { });
        appname = "Beeper";
        url = l.forSystem {
          # aarch64-darwin = "https://download.beeper.com/versions/${version}/mac/dmg/arm64";
          aarch64-darwin = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-arm64-mac.zip";
          x86_64-linux = "https://download.beeper.com/versions/${version}/linux/appImage/x64";
        };
      in
      pkgs.stdenvNoCC.mkDerivation {
        inherit version;
        src = builtins.fetchurl { inherit url; sha256 = versions.${system}.${version}.sha256; };
        pname = l.slugify appname;
        nativeBuildInputs = [ pkgs.undmg ];
        buildInputs = [ pkgs.unzip ];
        unpackCmd = ''set -x
            echo "File to unpack: $curSrc"
            if ! [[ "$curSrc" =~ \.zip$ ]]; then echo "[ERROR] Expected a zip file"; return 1; fi
            runHook preUnpack
            echo "Unzipping $src to $PWD"
            unzip $src
            runHook postUnpack
          '';
        phases = [
          "unpackPhase"
          "installPhase"
        ];
        # sourceRoot = "${appname}.app";
        installPhase = ''
          mkdir -p "$out/Applications/${appname}.app"
          cp -a ./. "$out/Applications/${appname}.app/"
        '';
        meta = { description = "All your chats in one app"; homepage = "https://beeper.com"; };
      };
  };






  # ferdium =
  #   let
  #     version = "7.0.0";
  #     url = localLib.forSystem {
  #       aarch64-darwin = "https://github.com/ferdium/ferdium-app/releases/download/v${version}/Ferdium-mac-${version}-arm64.dmg";
  #     };
  #     src = localLib.forSystem {
  #       aarch64-darwin = { inherit url; sha = "sha256:1l89vpyx3pas1gij3a0cblbsda0m1vjv289wf8g6x9dq9kkrgxcj"; };
  #     };
  #   in
  #   localLib.installDmg {
  #     inherit url version; sha256 = src.sha;
  #     appname = "Ferdium";
  #     meta = { description = "All your services in one place built by the community"; homepage = "https://ferdium.org"; };
  #   };

  # transmission =
  #   let
  #     version = "4.0.6";
  #     src = localLib.forSystem {
  #       aarch64-darwin = { url = "https://github.com/transmission/transmission/releases/download/${version}/Transmission-${version}.dmg"; sha256 = "sha256:06kw4zkn6a3hd8s66hk77v4k0b7z7mn5h0y69hwgbhp0abqmg676"; };
  #     };
  #   in
  #   localLib.installDmg {
  #     inherit (src) url sha256;
  #     inherit version;
  #     appname = "Transmission";
  #     meta = { description = "Cross-platform BitTorrent client"; homepage = "https://transmissionbt.com"; };
  #   };
}
