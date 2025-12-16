{_, ...}: let
  types = {inherit (_.types.predicates) isInt;};
in
  {}
  // types
  // {
    _rootAliases = {inherit types;};
  }
