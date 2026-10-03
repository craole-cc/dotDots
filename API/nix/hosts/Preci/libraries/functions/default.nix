{lib ? import <nixpkgs/lib>, ...}: let
  __ = {inherit lib;};
  attrsets = import ./attrsets.nix __;
  fetchers = import ./fetchers.nix __;
  lists = import ./lists.nix __;
  strings = import ./strings.nix (__ // {inherit trivial;});
  trivial = import ./trivial.nix __;
  debug = import ./debug.nix (
    __ // {lix = {inherit trivial strings;};}
  );
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
