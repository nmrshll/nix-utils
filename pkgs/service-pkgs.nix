{

  handy = rec {
    versions = {
      x86_64-linux."0.6.4".sha256 = "sha256-tItYRJL0e5mQMRufWBh8zcqJPDkbLf98jW9yjB50Z4Q=";
      x86_64-darwin."0.6.4".sha256 = "sha256-yTRNaH/P5nMKT2oYk9b9oRH8s6PAi30Vtfw9TgE7WnE=";
      aarch64-darwin."0.6.4".sha256 = "sha256-9trjwzQIqM5Okvnj2GAlBxKajyBiM0HbNmw4JukUsF4=";
    };
    mkPackage = { pkgs, version ? "0.6.4", ... }:
      with builtins; let
        # arch =  if  then "aarch64" else "x86";
        arch = pkgs.stdenv.hostPlatform.uname.processor;
        url = if pkgs.lib.platforms.isDarwin then "$" else "";
        src = fetchurl {
          inherit url; sha256 = versions.${pkgs.system}.${version}.sha256;
        };
        pname = "handy";

      in
      pkgs.stdenv.mkDerivation {
        inherit pname version src;

        nativeBuildInputs =
          pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.autoPatchelfHook
            pkgs.dpkg
            pkgs.copyDesktopItems
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.makeWrapper
          ];

        buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.gcc-unwrapped.lib
          pkgs.alsa-lib
          pkgs.cairo
          pkgs.gdk-pixbuf
          pkgs.glib
          pkgs.gtk3
          pkgs.libsoup_3
          pkgs.openssl
          pkgs.vulkan-loader
          pkgs.webkitgtk_4_1
        ];

        runtimeDependencies = pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.libayatana-appindicator
        ];

        desktopItems = pkgs.lib.optionals pkgs.stdenv.isLinux [
          (pkgs.makeDesktopItem {
            name = "handy";
            desktopName = "Handy";
            comment = "Fast and accurate local transcription app";
            exec = "handy";
            icon = "handy";
            categories = [ "Audio" "AudioVideo" "Utility" ];
            startupNotify = true;
          })
        ];

        unpackPhase =
          if pkgs.stdenv.isLinux then ''
            runHook preUnpack
            dpkg -x $src .
            runHook postUnpack
          ''
          else ''
            runHook preUnpack
            mkdir -p ./unpacked
            tar -xzf $src -C ./unpacked
            runHook postUnpack
          '';
        installPhase =
          if pkgs.stdenv.isLinux then ''
            runHook preInstall
            # Install the binary
            install -Dm755 usr/bin/handy $out/bin/handy
            # Install resources
            mkdir -p $out/lib/Handy/resources
            cp -r usr/lib/Handy/resources/* $out/lib/Handy/resources/
            # Install icons
            mkdir -p $out/share/icons/hicolor
            if [ -d usr/share/icons/hicolor ]; then
              cp -r usr/share/icons/hicolor/* $out/share/icons/hicolor/
            fi
            runHook postInstall
          ''
          else ''
            runHook preInstall
            mkdir -p $out/Applications
            cp -r ./unpacked/Handy.app $out/Applications/
            # Create a wrapper script in bin
            mkdir -p $out/bin
            makeWrapper $out/Applications/Handy.app/Contents/MacOS/Handy $out/bin/handy
            runHook postInstall
          '';

        meta = with pkgs.lib; {
          description = "Fast and accurate local transcription app using AI models";
          homepage = "https://handy.computer/";
          changelog = "https://github.com/cjpais/Handy/releases/tag/v${version}";
          sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          maintainers = [ ];
          platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
          mainProgram = "handy";
        };
      };
  };

}





####################



#   {
#   lib,
#   stdenv,
#   fetchurl,
#   autoPatchelfHook,
#   gcc-unwrapped,
#   dpkg,
#   makeWrapper,
#   makeDesktopItem,
#   copyDesktopItems,
#   # Runtime dependencies for Linux
#   alsa-lib,
#   cairo,
#   gdk-pixbuf,
#   glib,
#   gtk3,
#   libayatana-appindicator,
#   libsoup_3,
#   openssl,
#   vulkan-loader,
#   webkitgtk_4_1,
#   }:

#   let
#   pname = "handy";
#   versionData = builtins.fromJSON (builtins.readFile ./hashes.json);
#   inherit (versionData) version hashes;

#   # Linux uses deb packages, macOS uses app tarballs
#   srcs = {
#     x86_64-linux = fetchurl {
#       url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.deb";
#       hash = hashes.x86_64-linux;
#     };
#     x86_64-darwin = fetchurl {
#       url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_x64.app.tar.gz";
#       hash = hashes.x86_64-darwin;
#     };
#     aarch64-darwin = fetchurl {
#       url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_aarch64.app.tar.gz";
#       hash = hashes.aarch64-darwin;
#     };
#   };

#   src =
#     srcs.${stdenv.hostPlatform.system}
#       or (throw "Unsupported system: ${stdenv.hostPlatform.system}. Supported systems: x86_64-linux, x86_64-darwin, aarch64-darwin");

#   desktopItem = makeDesktopItem {
#     name = "handy";
#     desktopName = "Handy";
#     comment = "Fast and accurate local transcription app";
#     exec = "handy";
#     icon = "handy";
#     categories = [
#       "Audio"
#       "AudioVideo"
#       "Utility"
#     ];
#     startupNotify = true;
#   };
#   in
#   stdenv.mkDerivation {
#   inherit pname version src;

#   nativeBuildInputs =
#     lib.optionals stdenv.isLinux [
#       autoPatchelfHook
#       dpkg
#       copyDesktopItems
#     ]
#     ++ lib.optionals stdenv.isDarwin [
#       makeWrapper
#     ];

#   buildInputs = lib.optionals stdenv.isLinux [
#     gcc-unwrapped.lib
#     alsa-lib
#     cairo
#     gdk-pixbuf
#     glib
#     gtk3
#     libsoup_3
#     openssl
#     vulkan-loader
#     webkitgtk_4_1
#   ];

#   runtimeDependencies = lib.optionals stdenv.isLinux [
#     stdenv.cc.cc.lib
#     libayatana-appindicator
#   ];

#   desktopItems = lib.optionals stdenv.isLinux [ desktopItem ];

#   unpackPhase =
#     if stdenv.isLinux then
#       ''
#         runHook preUnpack

#         dpkg -x $src .

#         runHook postUnpack
#       ''
#     else
#       ''
#         runHook preUnpack

#         mkdir -p ./unpacked
#         tar -xzf $src -C ./unpacked

#         runHook postUnpack
#       '';

#   installPhase =
#     if stdenv.isLinux then
#       ''
#         runHook preInstall

#         # Install the binary
#         install -Dm755 usr/bin/handy $out/bin/handy

#         # Install resources
#         mkdir -p $out/lib/Handy/resources
#         cp -r usr/lib/Handy/resources/* $out/lib/Handy/resources/

#         # Install icons
#         mkdir -p $out/share/icons/hicolor
#         if [ -d usr/share/icons/hicolor ]; then
#           cp -r usr/share/icons/hicolor/* $out/share/icons/hicolor/
#         fi

#         runHook postInstall
#       ''
#     else
#       ''
#         runHook preInstall

#         mkdir -p $out/Applications
#         cp -r ./unpacked/Handy.app $out/Applications/

#         # Create a wrapper script in bin
#         mkdir -p $out/bin
#         makeWrapper $out/Applications/Handy.app/Contents/MacOS/Handy $out/bin/handy

#         runHook postInstall
#       '';

#   meta = with lib; {
#     description = "Fast and accurate local transcription app using AI models";
#     homepage = "https://handy.computer/";
#     changelog = "https://github.com/cjpais/Handy/releases/tag/v${version}";
#     license = licenses.unfree;
#     sourceProvenance = with sourceTypes; [ binaryNativeCode ];
#     maintainers = with maintainers; [ ];
#     platforms = [
#       "x86_64-linux"
#       "x86_64-darwin"
#       "aarch64-darwin"
#     ];
#     mainProgram = "handy";
#   };
# }



