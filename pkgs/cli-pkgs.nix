with builtins; rec {

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





}
