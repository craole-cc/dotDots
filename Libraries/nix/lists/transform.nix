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

  indentedMsg = {
    size ? 7,
    bullet ? "-",
    items,
    msg,
  }: "\n${indent 7}${msg}:\n${indented {
    size = size + 2;
    inherit items bullet;
  }}";
in {
  inherit indented indentedMsg;

  _rootAliases = {
    indentedList = indented;
    indentedAfterError = indentedMsg;
  };
}
