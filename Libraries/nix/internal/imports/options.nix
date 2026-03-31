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
  access = {
    inherit (lib.options) showFiles showOption;
  };

  construction = {
    inherit
      (lib.options)
      mergeUniqueOption
      mkEnableOption
      mkOption
      mkPackageOption
      mkSinkUndeclaredOptions
      ;
  };

  predicates = {
    inherit (lib.options) isOption;
    inherit (lib.types) isOptionType;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
