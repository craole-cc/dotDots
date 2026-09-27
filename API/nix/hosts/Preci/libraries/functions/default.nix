{lib ? import <nixpkgs/lib>, ...}: let
  args = {inherit lib;};
  attrsets = import ./attrsets.nix {};
  fetchers = import ./fetchers.nix {};
  trivial = import ./trivial.nix args;
  strings = import ./strings.nix args;
  debug = import ./debug.nix (
    args // {lix = {inherit trivial strings;};}
  );
in {
  inherit
    attrsets
    debug
    fetchers
    strings
    trivial
    ;
}
