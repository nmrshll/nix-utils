{
  openspec = rec {
    versions = {
      aarch64-darwin."0.16.0".sha256 = "eBZvgjjEzhoO1Gt4B3lsgOvJ98uGq7gaqdXQ40i0SqY=";
      aarch64-darwin."0.15.0".sha256 = "Wb0m2ZRmOXNj6DOK9cyGYzFLNTQjLO+czDxzIHfADnY=";
    };
    mkPkg = { pkgs, version ? "0.16.0", system ? pkgs.stdenv.hostPlatform.system, ... }: pkgs.buildNpmPackage rec {
      inherit version;
      pname = "openspec";

      src = pkgs.fetchFromGitHub {
        owner = "Fission-AI";
        repo = "OpenSpec";
        rev = "v${version}";
        sha256 = versions.${system}.${version}.sha256;
      };
      pnpmDeps = pkgs.pnpm.fetchDeps {
        inherit pname version src;
        fetcherVersion = 2;
        hash = "sha256-qqIdSF41gv4EDxEKP0sfpW1xW+3SMES9oGf2ru1lUnE=";
      };
      npmConfigHook = pkgs.pnpm.configHook;
      npmDeps = pnpmDeps;
      dontNpmPrune = true; # hangs forever on both Linux/darwin

      meta = with pkgs.lib; {
        description = "Spec-driven development framework for AI coding assistants";
        homepage = "https://github.com/Fission-AI/OpenSpec";
        license = licenses.mit;
        mainProgram = "openspec";
        platforms = platforms.all;
      };
    };
  };

  # NOW PART OF NIXPKGS
  #  gemini-cli = { pkgs, lib, version ? "0.1.7", ... }:
  #     let
  #       versionDeps = {
  #         early-access = { hash = "sha256-KNnfo5hntQjvc377A39+QBemeJjMVDRnNuGY/93n3zc="; npmDepsHash = "sha256-/IAEcbER5cr6/9BFZYuV2j1jgA75eeFxaLXdh1T3bMA="; };
  #         "0.1.7" = { hash = "sha256-DAenod/w9BydYdYsOnuLj7kCQRcTnZ81tf4MhLUug6c="; npmDepsHash = "sha256-otogkSsKJ5j1BY00y4SRhL9pm7CK9nmzVisvGCDIMlU="; };
  #         "0.1.5" = { hash = "sha256-JgiK+8CtMrH5i4ohe+ipyYKogQCmUv5HTZgoKRNdnak="; npmDepsHash = "sha256-yoUAOo8OwUWG0gyI5AdwfRFzSZvSCd3HYzzpJRvdbiM="; };
  #       }.${version};
  #     in
  #     pkgs.buildNpmPackage {
  #       name = "gemini-cli";
  #       src = pkgs.fetchFromGitHub {
  #         owner = "google-gemini";
  #         repo = "gemini-cli";
  #         tag = if lib.hasPrefix "0." version then "v${version}" else "${version}";
  #         hash = versionDeps.hash;
  #       };
  #       npmDepsHash = versionDeps.npmDepsHash;

  #       nativeBuildInputs = [ pkgs.typescript ];
  #       fixupPhase = ''
  #         runHook preFixup
  #         find $out -type l -exec test ! -e {} \; -delete
  #         runHook postFixup
  #       '';
  #       # nativeInstallCheckInputs = [
  #       #   versionCheckHook
  #       # ];
  #       doInstallCheck = true;
  #       versionCheckProgram = "${placeholder "out"}/bin/gemini";
  #       versionCheckProgramArg = "--version";
  #       meta = {
  #         description = "Open-source AI agent that brings the power of Gemini directly into your terminal";
  #         homepage = "https://github.com/google-gemini/gemini-cli";
  #         changelog = "https://github.com/google-gemini/gemini-cli/releases/tag/v${version}";
  #         license = lib.licenses.asl20;
  #         maintainers = with lib.maintainers; [
  #           ryota2357
  #         ];
  #         mainProgram = "gemini";
  #       };
  #     };



}


# in

# builtins.foldl'
#   (a: b: builtins.deepSeq b (a // b))
# { }
#   (builtins.map
#     (pkgName:
#     let
#       pkgDef = builtins.getAttr pkgName pkgDefs;
#       versionedPkgs = builtins.listToAttrs (builtins.map
#         (version: {
#           name = "${pkgName}_${version}";
#           value = { pkgs, lib, ... }: (pkgDef.mkPkg { inherit pkgs lib version; });
#         })
#         (builtins.attrNames pkgDef.versions));
#       defaultPkg = { ${pkgName} = { pkgs, lib, ... }: (pkgDef.mkPkg { inherit pkgs lib; }); };
#     in
#     versionedPkgs // defaultPkg
#     )
#     (builtins.attrNames pkgDefs))
