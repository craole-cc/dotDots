{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  base = {lix = lib;};

  attrsets = import ./attrsets.nix base;
  fetchers = import ./fetchers.nix base;
  lists = import ./lists.nix base;

  trivial = import ./trivial.nix base;
  withTrivial = recursiveUpdate base {inherit trivial;};

  strings = import ./strings.nix withTrivial;
  withStrings = recursiveUpdate withTrivial {
    inherit trivial strings;
    lix = recursiveUpdate lib {inherit trivial strings;};
  };

  debug = import ./debug.nix withStrings;
in {
  inherit
    attrsets
    debug
    fetchers
    lists
    strings
    trivial
    ;
}
