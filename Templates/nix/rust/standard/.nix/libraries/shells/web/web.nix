{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkPkgs;
in {
  mkGroups = {
    pkgs ? mkPkgs {},
    includeWeb ? false,
    ...
  }:
    optionalAttrs includeWeb {
      web = {
        packages = {inherit (pkgs) deno pnpm prettierd;};
      };
    };
}
