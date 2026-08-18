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
    flattened = {} // access // combinators // predicates // primitives // {};
  };

  inherit
    (lib)
    attrsets
    filesystem
    lists
    options
    strings
    trivial
    types
    ;

  access = {inherit (builtins) typeOf;};

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
      ints
      lines
      number
      package
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
    inherit (trivial) isBool isFunction;
    inherit (filesystem) isPath;
    inherit (options) isOption;
    inherit (lists) isList;
    inherit
      (strings)
      isString
      isConvertibleWithToString
      isStringLike
      isValidPosixName
      isStorePath
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
