{
  _,
  lib,
  ...
}: let
  inherit (_.strings.transform) indent;
  inherit (lib.strings) concatStringsSep;

  indented = {
    size ? 2,
    bullet ? "-",
    items,
  }:
    concatStringsSep "\n" (map (i: "${indent size}${bullet} ${i}") items);
in {
  inherit indented;

  _rootAliases = {
    indentedList = indented;
  };
}
