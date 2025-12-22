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
