with builtins; {

  atlassian-cli = rec {
    versions = {
      aarch64-darwin."1.2.5-stable".sha256 = "sha256:1xij39cv16af7cs5pwyg3fb56kdmf2kvvrg0hizs4m0cly3pv00a";
    };
    mkPkg = { pkgs, version ? "1.2.5-stable", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        sysShort = { aarch64-darwin = "darwin"; x86_64-linux = "linux"; }.${pkgs.stdenv.hostPlatform.system};
        sysLong = { aarch64-darwin = "darwin_arm64"; x86_64-linux = "linux-x64"; }.${pkgs.stdenv.hostPlatform.system};
      in
      pkgs.stdenv.mkDerivation {
        inherit version;
        pname = "atlassian-cli";
        src = fetchTarball {
          url = "https://acli.atlassian.com/${sysShort}/${version}/acli_${version}_${sysLong}.tar.gz";
          sha256 = versions.${system}.${version}.sha256;
        };
        installPhase = ''
          mkdir -p $out/bin
          cp -r $src/acli $out/bin/acli
        '';
        meta = { description = "Atlassian CLI"; homepage = "https://acli.atlassian.com/"; };
      };
  };

  xcode = rec {
    versions = {
      aarch64-darwin."26.2".sha256 = "0lmmyq12c3pkhs6cwf9v5pna1rvn7h8idxq0i78yh7v47ia1vwvd";
    };
    mkPkg = { pkgs, version ? "26.2", system ? pkgs.stdenv.hostPlatform.system, ... }:
      let
        xip = fetchurl {
          url = "https://huggingface.co/datasets/nmarshall/nix-install-files/resolve/main/files/Xcode_${version}_Apple_silicon.xip?download=true";
          sha256 = versions.${system}.${version}.sha256;
          name = "Xcode_${version}_Apple_silicon.xip";
        };
      in
      pkgs.stdenv.mkDerivation {
        pname = "XCode.app";
        inherit version;
        src = xip;

        dontUnpack = true;
        buildPhase = ''
          ${pkgs.xar}/bin/xar -xf ${xip}
          ${pkgs.pbzx}/bin/pbzx -n Content | ${pkgs.cpio}/bin/cpio -i
          rm Metadata Content
          ${pkgs.rcodesign}/bin/rcodesign verify Xcode.app/Contents/MacOS/Xcode
        '';
        installPhase = ''mv Xcode.app $out'';

        meta = {
          description = "Automatically extracted Xcode from xip";
          platforms = pkgs.lib.platforms.darwin;
        };
      };
  };

}
