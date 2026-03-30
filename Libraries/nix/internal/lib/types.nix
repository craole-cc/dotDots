{lib, ...}: let
  __exports = {
    internal =
      {
        inherit
          combinators
          opaque
          predicates
          primitives
          submodules
          ;
      }
      // combinators
      // opaque
      // predicates
      // primitives
      // submodules
      // {};
    external = {};
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

  predicates = {
    inherit (builtins) typeOf;
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
  __exports.internal
