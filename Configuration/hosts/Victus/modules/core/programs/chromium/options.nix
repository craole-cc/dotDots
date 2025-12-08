{
  lib,
  pkg,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption literalExpression;
  inherit (lib.types) enum;
  inherit (lib.attrsets) attrNames;
  inherit (lib.strings) concatStringsSep;
in
{
  enable = mkEnableOption "Chromium-based Browser";
  variant = mkOption {
    type = enum (attrNames pkg);
    default = "chromium";
    example = literalExpression ''"brave"'';
    description = ''
      Which Chromium-based browser to use.
      Available options: ${concatStringsSep ", " (attrNames pkg)}.
    '';
  };
}
