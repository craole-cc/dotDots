{
  lix,
  mkLix,
  ...
}: let
  attrsets = import ./attrsets.nix {inherit lix;};
  fetchers = import ./fetchers.nix {inherit lix;};
  lists = import ./lists.nix {inherit lix;};
  trivial = import ./trivial.nix {inherit lix;};
  strings = import ./strings.nix (mkLix {inherit trivial;});
  debug = import ./debug.nix (mkLix {inherit trivial strings;});
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
