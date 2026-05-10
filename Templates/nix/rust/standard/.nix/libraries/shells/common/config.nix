{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.shells) common;
in {
  mkGroups = {
    pkgs,
    includeExtras ? false,
    includeWeb ? false,
    ...
  }:
    with common;
      {base = mkBase pkgs;}
      // optionalAttrs includeExtras (mkExtra pkgs)
      // optionalAttrs includeWeb (mkWeb pkgs);
}
