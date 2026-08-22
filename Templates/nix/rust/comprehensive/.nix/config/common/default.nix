{ lib, ... }:
let
  inherit (lib.attrsets) optionalAttrs;

  mkCommon =
    set:
    optionalAttrs set.enable {
      envrc = {
        source = ./envrc;
        target = ".envrc";
      };
      gitignore = {
        source = ./gitignore;
        target = ".gitignore";
      };
    };
in
{
  inherit mkCommon;
}
