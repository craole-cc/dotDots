{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        combinators
        opaque
        predicates
        primitives
        submodules
        ;
    };
    flattened =
      {}
      // access
      // combinators
      // opaque
      // predicates
      // primitives
      // submodules
      // {};
  };

  primitives = {
    inherit
      (lib.types)
      bool
      commas
      envVar
      float
      int
      lines
      number
      path
      pathInStore
      separatedString
      str
      strMatching
      ;
  };

  opaque = {
    inherit
      (lib.types)
      anything
      raw
      unspecified
      ;
  };

  submodules = {
    inherit
      (lib.types)
      submodule
      submoduleWith
      ;
  };

  combinators = {
    inherit
      (lib.types)
      attrs
      attrsOf
      either
      enum
      lazyAttrsOf
      listOf
      mkOptionType
      nonEmptyListOf
      nullOr
      oneOf
      ;
  };

  access = {
    inherit (builtins) typeOf;
  };

  predicates = {
    inherit (lib.attrsets) isAttrs isDerivation;
    inherit (lib.filesystem) isPath isStorePath;
    inherit (lib.lists) isList;
    inherit
      (lib.strings)
      isString
      isConvertibleWithToString
      isStringLike
      isPOSIXString
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
