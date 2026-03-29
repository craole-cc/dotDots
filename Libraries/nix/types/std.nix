{lib, ...}: let
  primatives = {
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
      nonEmptyListOf
      nullOr
      oneOf
      ;
  };

  constructors = {
    inherit (lib.types) mkOptionType;
  };

  predicates = {
    inherit
      (builtins)
      typeOf
      ;

    inherit
      (lib.attrsets)
      isDerivation
      isTypedAttrs
      isAllEnabledAttrs
      isAnyEnabledAttrs
      isWaylandEnabledAttrs
      ;

    inherit
      (lib.list)
      isList
      ;

    inherit
      (lib.strings)
      isString
      isConvertibleWithToString
      isStringLike
      isPOSIXString
      ;

    inherit
      (lib.filesystem)
      isPath
      isStorePath
      ;
  };
  # inherit
  #   (lib.strings)
  #   #~@ Strings
  #   isBinaryString
  #   isString
  #   isStringConvertible
  #   isStringLike
  #   isList
  #   #~@ Attrsets
  #   isAttrs
  #   isDerivation
  #   isTypedAttrs
  #   isAllEnabledAttrs
  #   isAnyEnabledAttrs
  #   isWaylandEnabledAttrs
  #   #~@ Filesystem
  #   isPath
  #   isPOSIXString
  #   isStorePath
  #   #~@ Debug
  #   isTest
  #   ;
in {
}
