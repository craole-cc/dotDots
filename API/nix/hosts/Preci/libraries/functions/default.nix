{
  lix,
  mkLix,
  ...
}: let
  attrsets = import ./attrsets.nix lix;
  fetchers = import ./fetchers.nix lix;
  lists = import ./lists.nix lix;
  trivial = import ./trivial.nix lix;

  withTrivial = mkLix {inherit trivial;};
  strings = import ./strings.nix withTrivial;

  withTrivialStrings = mkLix {inherit trivial strings;};
  debug = import ./debug.nix withTrivialStrings;
in
  (mkLix {
    inherit
      attrsets
      debug
      fetchers
      lists
      strings
      trivial
      ;
  }).lix
