# { lib, ... }:
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
    # pkgs.writeScriptBin "openspec" ''
    #     #!${pkgs.bash}/bin/bash
    #     echo "OpenSpec CLI version ${version} (placeholder script)"
    #     # Replace this with the actual command to run the openspec CLI.
    #     # For example, if it's an npm package, you might use:
    #     # exec ${pkgs.nodejs}/bin/npm exec openspec -- "$@"
    #   '';


  };


  # in
  # "";

  # lib.recursiveUpdate
  #   (lib.mapAttrs'
  #     (version: value: {
  #       name = " openspec_${version}";
  #       value = mkPackage { inherit pkgs lib version; };
  #     })
  #     versionDeps)
  #   # Provide a default 'openspec' that points to the latest/default version
  #   # This assumes "0.15.0"  is the default or only version.
  #   # Adjust if a different default logic is needed.
  #   { openspec = mkPackage { inherit pkgs lib; }; }

in
# lib.mergeAttrsList
  #   (lib.mapAttrsToList
  #     (pkgName: pkgDef:
  #     let
  #       versionedPkgs = lib.mapAttrs'
  #         (version: _: {
  #           name = "${pkgName}_${version}";
  #           value = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib version; });
  #         })
  #         pkgDef.versions;
  #       defaultPkg = { ${pkgName} = { pkgs, lib, ... }: (pkgDef.mkPackage { inherit pkgs lib; }); };
  #     in
  #     lib.recursiveUpdate versionedPkgs defaultPkg
  #     )
  #     pkgDefs
  #   )

  # lib.mapAttrs'
  #   (pkgName: pkgDef: {
  #     name = "${pkgName}";
  #     value = { pkgs, lib, ... }: pkgDef.mkPackage { inherit pkgs lib; };
  #   })
  #   pkgDefs


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





