{
  _,
  lib,
  ...
}: let
  inherit (_.strings.transform) indent;
  inherit (lib.strings) concatStringsSep;

  # indented = {
  #   size ? 2,
  #   bullet ? "-",
  #   items,
  # }:
  #   concatStringsSep "\n" (map (i: "${indent size}${bullet} ${i}") items);

  # indentedMsg = {
  #   title,
  #   items,
  #   size ? 7,
  #   bullet ? "-",
  # }: "\n${indent 7}${title}:\n${indented {
  #   size = size + 2;
  #   inherit items bullet;
  # }}";
  indented = {
    items,
    title ? null,
    size ? 2,
    bullet ? "-",
  }:
    if title != null
    then "\n${indent size}${title}:\n${concatStringsSep "\n" (
      map (i: "${indent (size + 2)}${bullet} ${i}") items
    )}"
    else "\n${concatStringsSep "\n" (
      map (i: "${indent size}${bullet} ${i}") items
    )}";

  indentedForError = {
    items,
    title ? null,
    size ? 8,
    bullet ? "-",
  }:
    indented {inherit items title size bullet;};
in {
  inherit indented indentedForError;

  _rootAliases = {
    indentedList = indented;
    indentedListForError = indentedForError;
  };
}
