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
        predicates
        primitives
        ;
    };
    flattened =
      {}
      // access
      // combinators
      // predicates
      // primitives
      // {};
  };

  inherit
    (lib)
    attrsets
    filesystem
    lists
    strings
    types
    ;

  access = {
    inherit (builtins) typeOf;
  };

  combinators = {
    inherit
      (types)
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
      submodule
      submoduleWith
      ;
  };

  primitives = {
    inherit
      (types)
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
      anything
      raw
      unspecified
      ;
  };

  predicates = {
    inherit (attrsets) isAttrs isDerivation;
    inherit (filesystem) isPath isStorePath;
    inherit (lists) isList;
    inherit
      (strings)
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
