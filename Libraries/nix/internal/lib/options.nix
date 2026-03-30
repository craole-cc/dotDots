{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        declaration
        introspection
        ;
    };
    flattened =
      {}
      // declaration
      // introspection
      // {};
  };

  declaration = {
    inherit
      (lib.options)
      mergeUniqueOption
      mkEnableOption
      mkOption
      mkPackageOption
      mkSinkUndeclaredOptions
      ;
  };

  introspection = {
    inherit
      (lib.options)
      isOption
      showFiles
      showOption
      ;

    inherit
      (lib.types)
      isOptionType
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
