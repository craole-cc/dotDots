{
  lib,
  strings,
  trivial,
  ...
}: let
  inherit (lib.attrsets) attrByPath;
  inherit (strings) showPath;
  inherit (trivial) isEmpty;

  requireNonEmpty = {
    context,
    path,
    set,
  }: let
    value = attrByPath path null set;
    label = showPath path;
  in
    if value == null
    then throw "${context}: missing required attribute '${label}'"
    else if isEmpty value
    then throw "${context}: required attribute '${label}' must not be empty"
    else true;

  #> Assert an arbitrary condition, with a contextual message on failure
  requireThat = {
    context,
    message,
    condition,
  }:
    if condition
    then true
    else throw "${context}: ${message}";
in {inherit requireNonEmpty requireThat;}
