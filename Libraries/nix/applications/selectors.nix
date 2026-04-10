# helpers/selectors.nix
# Layer 3 — primitive set selectors.
# Each function takes a `set` and returns a filtered subset.
# No query naming or grouping — just raw filterAttrs wrappers.
# Depends on: primitives
{_, primitives}: let
  inherit (_.attrsets.access) attrByPath;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (primitives) toValue;
in {
  # Keep apps where bool field is true
  withFlag = {field, set}:
    filterAttrs (_: toValue {inherit field; default = false;}) set;

  # Keep apps where bool field is false or absent
  withoutFlag = {field, set}:
    filterAttrs (_: a: !(toValue {inherit field; default = false;} a)) set;

  # Keep apps where field != value  (useful for excluding a sentinel)
  withNeq = {field, default ? null, value ? null, set}:
    filterAttrs (_: a: toValue {inherit field default;} a != value) set;

  # Merge config.home + config.file into a resolved config.path attribute
  normalizeConfig = {set, path ? ["config"]}:
    mapAttrs (_: a: let cfg = attrByPath path null a; in
      if cfg != null && cfg.home != null && cfg.file != null
      then recursiveUpdate a (setAttrByPath path (cfg // {path = "${cfg.home}/${cfg.file}";}))
      else a
    ) set;
}
