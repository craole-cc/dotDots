# helpers/predicates.nix
# Layer 2 — set-membership predicates.
# Answers "does this set have apps with field X?" questions.
# Depends on: primitives
{_, primitives}: let
  inherit (_.attrsets.access) attrValues;
  inherit (_.lists.predicates) isList;
  inherit (_.lists.selection) filter;
  inherit (primitives) toValue;
in {
  # True when at least one app in `set` has a non-null value at `field`
  hasField = {field, set}:
    filter (a: toValue {inherit field;} a != null) (attrValues set) != [];

  # True when at least one app in `set` has a list value at `field`
  hasListField = {field, set}:
    filter (a: isList (toValue {inherit field;} a)) (attrValues set) != [];
}
