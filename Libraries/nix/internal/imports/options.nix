{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        construction
        predicates
        ;
    };
    flattened =
      {}
      // access
      // construction
      // predicates
      // {};
  };

  inherit (lib) options types;

  access = {
    inherit (options) showFiles showOption;
  };

  construction = {
    inherit
      (options)
      mergeUniqueOption
      mkEnableOption
      mkOption
      mkPackageOption
      mkSinkUndeclaredOptions
      ;
    inherit (types) mkOptionType;
  };

  predicates = {
    inherit (options) isOption;
    inherit (types) isOptionType;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
