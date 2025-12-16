{_, ...}: let
  types = _.types.predicates;
in
  types
  // {
    _rootAliases = {inherit types;};
  }
