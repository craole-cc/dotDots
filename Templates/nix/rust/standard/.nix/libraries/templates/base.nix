{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkBin mkBins mkPkg;
  inherit (lib.shells) mkPackagesFrom setSource;
  inherit (lib.strings) mkStyledOutput;
in {
  mkBase = pkgs: let
    inherit (pkgs.stdenv) isLinux;

    templates = {
      envrc = {
        source = setSource ["base" "envrc"];
        target = ".envrc";
      };
      gitignore = {
        source = setSource ["base" "gitignore"];
        target = ".gitignore";
      };
      mise = {
        source = setSource ["base" "mise"];
        target = [".mise.toml" "mise.toml"];
      };
      shellcheck = {
        source = setSource ["base" "shellcheckrc"];
        target = [".shellcheckrc" "shellcheckrc"];
      };
      markdownlint = {
        source = setSource ["base" "markdownlint-cli2.yaml"];
        target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
      };
      treefmt = {
        source = setSource ["base" "treefmt.toml"];
        target = [".treefmt.toml" "treefmt.toml"];
      };
    };

}
