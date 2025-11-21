{
  openspec = { pkgs, lib, ... }:
    let
      versionDeps = {
        "0.15.0" = { hash = "sha256-0xhfq1vj0wrwrjffyb136hslncb3hv6gb2ikx1ip6fb6jkcjdgar"; npmDepsHash = ""; };
      };
      mkPackage = { pkgs, lib, version ? "0.15.0", ... }: pkgs.buildNpmPackage {
        name = "openspec";
        src = pkgs.fetchFromGitHub {
          owner = "Fission-AI";
          repo = "OpenSpec";
          tag = "v${version}";
          hash = versionDeps.${version}.hash;
        };
        npmDepsHash = versionDeps.${version}.npmDepsHash;

        nativeBuildInputs = [ pkgs.typescript ];

        meta = {
          description = "OpenSpec CLI";
          homepage = "https://github.com/Fission-AI/OpenSpec";
          license = lib.licenses.mit;
          mainProgram = "openspec";
        };
      };
    in
    {
      packages = lib.mapAttrs'
        (version: value: {
          name = "openspec_${version}";
          value = mkPackage { inherit pkgs lib version; };
        })
        versionDeps;
    };
}


