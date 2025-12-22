let
  localLib = import ./utils.nix { };
  l = builtins // localLib;
in
{
  # anytype =
  #   let
  #     version = "0.47.3";
  #     src = localLib.forSystem {
  #       aarch64-darwin = { url = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg"; sha256 = "sha256:1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj"; };
  #     };
  #   in
  #   localLib.installDmg {
  #     inherit (src) url sha256;
  #     inherit version;
  #     appname = "AnyType";
  #     meta = { description = "A space for your thoughts, private, local, p2p & open"; homepage = "https://anytype.io/"; };
  #   };
  anytype = rec{
    versions = {
      aarch64-darwin."0.47.3".sha256 = "sha256:1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj";
    };
    mkPkg = { pkgs, version ? "0.47.3", system ? pkgs.stdenv.hostPlatform.system, ... }:
      # let src = l.forSystem { aarch64-darwin = { url = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg"; sha256 = "sha256:1xs52cnr81fzqg4cp7cbvmlnjgi548nv8sxbvdsd4gvl3v09c3qj"; }; }; 
      # in
      let url = l.forSystem { aarch64-darwin = "https://anytype-release.fra1.cdn.digitaloceanspaces.com/Anytype-${version}-mac-arm64.dmg"; };
      in l.installDmg {
        # inherit  url sha256;
        inherit version url;
        sha256 = versions.${system}.${version}.sha256;
        appname = "AnyType";
        meta = { description = "A space for your thoughts, private, local, p2p & open"; homepage = "https://anytype.io/"; };
      };
  };
}
