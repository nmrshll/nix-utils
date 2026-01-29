with builtins; let
  dbg = o: trace (toJSON o) o;

in
{
  anytype = rec {
    versions = {
      aarch64-darwin."0.53.1".sha256 = "0v49qj232mkpx54z99nbmiafkvagkhk2xy8h8yyz95jizklhbh6g";
      aarch64-darwin."0.52.4".sha256 = "05syxapx4i5qrr2l5f12vs6wn74zixqn2d83mz0lxlhyi7x635kp";
      aarch64-darwin."0.47.3".sha256 = "1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj";
    };
    mkPkg = { pkgs, version ? "0.53.1", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // pkgs.callPackage ../utils/utils.nix { };
        url = l.forSystem {
          aarch64-darwin = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg";
        };
      in
      l.darwin.installDmg {
        inherit version url;
        sha256 = versions.${system}.${version}.sha256;
        appname = "AnyType";
        meta = { description = "A space for your thoughts, private, local, p2p & open"; homepage = "https://anytype.io/"; };
      };
  };

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

  transmission = rec {
    versions = {
      aarch64-darwin."4.0.6".sha256 = "sha256:06kw4zkn6a3hd8s66hk77v4k0b7z7mn5h0y69hwgbhp0abqmg676";
    };
    mkPkg = { pkgs, version ? "4.0.6", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // (pkgs.callPackage ../utils/utils.nix { });
        url = "https://github.com/transmission/transmission/releases/download/${version}/Transmission-${version}.dmg";
      in
      l.darwin.installDmg {
        inherit version url;
        sha256 = versions.${system}.${version}.sha256;
        appname = "Transmission";
        meta = { description = "Cross-platform BitTorrent client"; homepage = "https://transmissionbt.com"; };
      };
  };

  finicky = rec {
    versions = {
      aarch64-darwin."4.1.4".sha256 = "sha256:13ayk8jslvxdqaba1ay2kr3hw0g2hr4lpadll9cv4zglz94xj81b";
    };
    mkPkg = { pkgs, version ? "4.1.4", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // (pkgs.callPackage ../utils/utils.nix { });
        # versionHashes = { aarch64-darwin."4.1.4" = "sha256:13ayk8jslvxdqaba1ay2kr3hw0g2hr4lpadll9cv4zglz94xj81b"; }.${pkgs.system};
        url = {
          aarch64-darwin = "https://github.com/johnste/finicky/releases/download/v${version}/Finicky.dmg";
        }.${pkgs.system};
      in
      l.darwin.installDmg {
        inherit url version;
        sha256 = versions.${system}.${version}.sha256;
        appname = "Finicky";
        meta = { description = "A macOS app for customizing which browser to start"; homepage = "https://github.com/johnste/finicky"; };
      };
  };

  comfy-ui = rec {
    versions = {
      aarch64-darwin."241012ess7yxs0e".sha256 = "0fbiwl0kir80gyiqqm5xrvsdwqj4fjws0k2slcrq2g4xkn7cwv7g";
    };
    mkPkg = { pkgs, version ? "241012ess7yxs0e", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        l = builtins // (pkgs.callPackage ../utils/utils.nix { });
        # versions = {
        #   aarch64-darwin."241012ess7yxs0e" = "0fbiwl0kir80gyiqqm5xrvsdwqj4fjws0k2slcrq2g4xkn7cwv7g";
        # }.${pkgs.system}.${version};
      in
      l.darwin.installDmg {
        inherit version;
        sha256 = versions.${system}.${version}.sha256;
        url = "https://dl.todesktop.com/${version}/mac/dmg/arm64";
        appname = "ComfyUI";
        meta = { description = "ComfyUI is a powerful, flexible, and user-friendly interface for Stable Diffusion."; homepage = "https://www.comfy.org/"; };
      };
  };

  # ABANDONED
  # ito = { pkgs, version ? "0.9.0" }:
  #   let
  #     versionHashes = {
  #       aarch64-darwin."0.9.0" = "sha256:0ii3mgknaxyrk7xamzn6sqp2828v2rsq8w38s4yqrkfhs53aclq6";
  #     }.${pkgs.system};
  #     url = {
  #       aarch64-darwin = "https://github.com/heyito/ito/releases/download/v${version}/Ito-Installer.dmg";
  #     }.${pkgs.system};
  #   in
  #   localLib.installDmg {
  #     inherit url version;
  #     sha256 = versionHashes.${version};
  #     appname = "Ito";
  #     meta = { source = "https://github.com/heyito/ito"; description = "Type with your Voice"; homepage = "https://www.ito.ai/"; };
  #   };

  # ABANDONED
  # tome = { pkgs, version ? "0.2.0" }:
  #   let
  #     versionHashes = {
  #       aarch64-darwin."0.2.0" = "sha256:1z1rxb0xavi9idf100i7mimsrgkivyh860818yy9zbryy2af2dv8";
  #     }.${pkgs.system};
  #     url = {
  #       aarch64-darwin = "https://github.com/joshkotrous/tome/releases/download/v${version}/tome-mac-arm64.dmg";
  #     }.${pkgs.system};
  #   in
  #   localLib.installDmg {
  #     inherit url version;
  #     sha256 = versionHashes.${version};
  #     appname = "Tome";
  #     meta = { source = "https://github.com/joshkotrous/tome"; description = "AI-native database client that translates natural language into perfect queries"; homepage = "https://tome.lang/"; };
  #   };

  # kdeConnect = rec {
  #   versions = {
  #     aarch64-darwin."5415".sha256 = "1q3dsgnr6v1dwvffllfin19h7qq516da7iiqyxc0fkf71f1jvy70";
  #   };
  #   mkPkg = { pkgs, version ? "5415", system ? pkgs.stdenv.hostPlatform.system, ... }:
  #     let
  #       l = builtins // (pkgs.callPackage ../utils/utils.nix { });
  #       # sha256 = {
  #       #   aarch64-darwin."5415" = "1q3dsgnr6v1dwvffllfin19h7qq516da7iiqyxc0fkf71f1jvy70";
  #       # }.${pkgs.system}.${version};
  #     in
  #     l.darwin.installDmg {
  #       inherit version;
  #       sha256 = versions.${system}.${version}.sha256;
  #       url = l.forSystem {
  #         aarch64-darwin = "https://origin.cdn.kde.org/ci-builds/network/kdeconnect-kde/master/macos-arm64/kdeconnect-kde-master-${version}-macos-clang-arm64.dmg";
  #       };
  #       appname = "KDEConnect";
  #       meta = { source = "https://invent.kde.org/explore/groups"; description = "Enabling communication between all your devices"; homepage = "https://kdeconnect.kde.org/"; };
  #     };
  # };

  lulu = rec {
    versions = {
      aarch64-darwin."4.2.0".sha256 = "1yl75hw5psblcb6biwxdp2mjp3n4dclyaj961mh3f6v8bya6ylcj";
      aarch64-darwin."3.1.5".sha256 = "eFrOZv6KSZlmLtyPORrD2Low/e7m7HU1WeuT/w8Us7I=";
    };
    mkPkg = { pkgs, lib, version ? "4.2.0", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        appName = "LuLu";
        pname = lib.toLower appName;
      in
      pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = fetchurl {
          url = "https://github.com/objective-see/LuLu/releases/download/v${version}/LuLu_${version}.dmg";
          sha256 = versions.${system}.${version}.sha256;
        };
        sourceRoot = ".";
        nativeBuildInputs = [ pkgs.makeWrapper pkgs.undmg ];

        installPhase = ''
          mkdir -p $out/Applications
          cp -r *.app $out/Applications
          # makeWrapper $out/Applications/${appName}.app/Contents/MacOS/${appName} $out/bin/${pname}
        '';

        meta = with lib; {
          description = "LuLu is the free open-source macOS firewall";
          homepage = "https://github.com/objective-see/LuLu";
          license = licenses.gpl3Only;
          maintainers = [ ];
          platforms = platforms.darwin;
          sourceProvenance = [ sourceTypes.binaryNativeCode ];
          mainProgram = pname;
        };
      };
  };
  lulu-installer = rec {
    versions = {
      aarch64-darwin."4.2.0".sha256 = "1yl75hw5psblcb6biwxdp2mjp3n4dclyaj961mh3f6v8bya6ylcj";
    };
    mkPkg = { pkgs, lib, version ? "4.2.0", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        src = fetchurl {
          url = "https://github.com/objective-see/LuLu/releases/download/v${version}/LuLu_${version}.dmg";
          sha256 = versions.${system}.${version}.sha256;
        };
        install-script = pkgs.writeText "install-lulu" ''
          set -euo pipefail # cleanup called on fail

          if [ -d "/Applications/LuLu.app" ]; then
            installed_version=$(defaults read /Applications/LuLu.app/Contents/Info.plist CFBundleShortVersionString)
            if [ "${version}" = "$installed_version" ]; then exit 0; fi
          fi
          
          MOUNT_POINT="/tmp/LuLu_Mount_$$"
          cleanup() {
            if [ -d "$MOUNT_POINT" ]; then
              hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
              rm -rf "$MOUNT_POINT"
            fi
          }
          trap cleanup EXIT

          mkdir -p "$MOUNT_POINT"
          hdiutil attach "${src}" -mountpoint "$MOUNT_POINT" -nobrowse -quiet
          sudo cp -R "$MOUNT_POINT/LuLu.app" /Applications/
        '';
      in
      # writeShellScriptBin doesn't expose version to caller -> mkDerivation
      pkgs.stdenvNoCC.mkDerivation {
        pname = "install-lulu";
        inherit version src;
        dontUnpack = true; # default is undmg
        sourceRoot = "."; # Prevent unpack errors
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cat ${install-script} > $out/bin/install-lulu
          chmod +x $out/bin/install-lulu
          runHook postInstall
        '';
      };
  };
}
