with builtins; rec {
  xcode-xip = rec {
    versions = {
      aarch64-darwin."26.2_Apple_silicon".sha256 = "0lmmyq12c3pkhs6cwf9v5pna1rvn7h8idxq0i78yh7v47ia1vwvd";
    };
    mkPkg = { pkgs, version ? "26.2_Apple_silicon", system ? pkgs.stdenv.hostPlatform.system, lib, ... }: (pkgs.fetchurl {
      url = "https://huggingface.co/datasets/nmarshall/nix-install-files/resolve/main/files/Xcode_${version}.xip?download=true";
      sha256 = versions.${system}.${version}.sha256;
      name = "Xcode_${version}.xip";
      passthru = {
        version = lib.removeSuffix "_Universal" (lib.removeSuffix "_Apple_silicon" version);
      };
    });
  };

  # install-xcode.mkPkg = { pkgs, version ? "26.2_Apple_silicon", system ? pkgs.stdenv.hostPlatform.system, lib, ... }:
  #   let
  #     xip = xcode-xip.mkPkg { inherit version pkgs system lib; };
  #     xcode_app_versions = {
  #       "26.2_Apple_silicon".sha256 = "YxMVppJwRzTA6xWOILxVjLdl0bNmtZSifG/KQx6inRE=";
  #     };
  #   in
  #   pkgs.writeShellScriptBin "install-xcode" ''
  #     XCODE_APP_SHA256="${xcode_app_versions.${version}.sha256}"
  #     XCODE_APP_NAME="Xcode.app"
  #     XCODE_APP_STORE_PATH_EXPECTED=$(nix-store --print-fixed-path --recursive sha256 "$XCODE_APP_SHA256" "$XCODE_APP_NAME")
  #     DEV_DIR="$XCODE_APP_STORE_PATH_EXPECTED/Contents/Developer"
  #     WD=$(mktemp -d)
  #     cd "$WD"

  #     if [ ! -e "$XCODE_APP_STORE_PATH_EXPECTED" ]; then
  #         echo "Xcode not found in store. Expanding..."
  #         install -m 644 "${xip}" "$WD/XCode_${version}.xip"
  #         /usr/bin/xip --expand "$WD/XCode_${version}.xip"
  #         nix-store --add-fixed --recursive sha256 "$WD/Xcode_${version}.app"
  #     else
  #         echo "Xcode already exists at $XCODE_APP_STORE_PATH_EXPECTED. Skipping expansion."
  #     fi
  #     sudo xcode-select -s "DEV_DIR"

  #     if ! xcodebuild -checkFirstLaunchStatus > /dev/null 2>&1; then
  #       yes agree | sudo xcodebuild -license accept
  #       xcodebuild -runFirstLaunch
  #     else
  #       echo "Xcode already initialized."
  #     fi
  #   '';

  # xcode = {
  #   mkPkg = { pkgs, version ? "26.2_Apple_silicon", system ? pkgs.stdenv.hostPlatform.system, lib, ... }:
  #     let xip = xcode-xip.mkPkg { inherit version pkgs system lib; };
  #     in pkgs.stdenv.mkDerivation {
  #       pname = "XCode.app";
  #       inherit version;
  #       src = xip;
  #       # __noChroot = true; # break the nix sandbox. For '/usr/bin/xip --expand'. Doesn't work.
  #       dontUnpack = true;
  #       buildPhase =
  #         # if pkgs.stdenv.buildPlatform.isDarwin then ''set -x;
  #         #   cp "${xip}" ./Xcode_${version}.xip
  #         #   chmod +w Xcode_${version}.xip
  #         #   /usr/bin/xip --expand Xcode_${version}.xip
  #         #   ls -la
  #         #   exit 1
  #         # '' else 
  #         ''
  #           ${pkgs.xar}/bin/xar -xf ${xip}
  #           ${pkgs.pbzx}/bin/pbzx -n Content | ${pkgs.cpio}/bin/cpio -i --verbose --preserve-modification-time --make-directories
  #           rm Metadata Content
  #           ${pkgs.rcodesign}/bin/rcodesign verify Xcode.app/Contents/MacOS/Xcode
  #         '';
  #       installPhase = ''mv Xcode.app $out'';
  #       # postFixup = '' # Doesn't work. tried self-signing binaries. xcodebuild doesn't accept that.
  #       #   find $out -type f \( -perm -u=x -o -name "*.so" -o -name "*.dylib" \) -exec \
  #       #     /usr/bin/codesign --force --sign - {} +
  #       # '';

  #       meta = {
  #         description = "Automatically extracted Xcode from xip";
  #         platforms = pkgs.lib.platforms.darwin;
  #       };
  #     };
  # };
}
