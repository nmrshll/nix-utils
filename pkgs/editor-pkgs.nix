let
  pkgDefs.openspec = rec {
    versions = {
      "0.15.0" = { hash = "sha256-0xhfq1vj0wrwrjffyb136hslncb3hv6gb2ikx1ip6fb6jkcjdgar"; npmDepsHash = ""; };
    };
    mkPackage = { pkgs, lib, version ? "0.15.0", ... }:
      pkgs.buildNpmPackage {
        name = "openspec";
        src = pkgs.fetchFromGitHub {
          owner = "Fission-AI";
          repo = "OpenSpec";
          tag = "v${version}";
          hash = versions.${version}.hash;
        };
        npmDepsHash = versions.${version}.npmDepsHash;

        nativeBuildInputs = [ pkgs.typescript ];

        meta = {
          description = "OpenSpec CLI";
          homepage = "https://github.com/Fission-AI/OpenSpec";
          license = lib.licenses.mit;
          mainProgram = "openspec";
        };
      };
  };


in
builtins.foldl'
  (a: b: builtins.deepSeq b (a // b))
{ }
  (builtins.map
    (pkgName:
    let
      pkgDef = builtins.getAttr pkgName pkgDefs;
      versionedPkgs = builtins.listToAttrs (builtins.map
        (version: {
          name = "${pkgName}_${version}";
          value = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib version; });
        })
        (builtins.attrNames pkgDef.versions));
      defaultPkg = { ${pkgName} = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib; }); };
    in
    versionedPkgs // defaultPkg
    )
    (builtins.attrNames pkgDefs))





