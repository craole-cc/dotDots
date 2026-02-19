{lib, ...}: let
  inherit
    (lib.strings)
    typeOf
    isAttrs
    isPath
    isValidPosixName
    isConvertibleWithToString
    isStorePath
    isString
    isList
    isStringLike
    ;
  inherit (lib.trivial) isBool isFunction isFloat isInt;

  isBinaryString = s:
    typeOf s == "string" && (s == "0" || s == "1");

  isSpecial = v: isAttrs v && (v._type or null) != null;

  isTest = test:
    isAttrs test
    && test ? expected
    && test ? result
    && test ? passed;

  exports = {
    inherit
      isAttrs
      isBinaryString
      isBool
      isConvertibleWithToString
      isFloat
      isFunction
      isInt
      isList
      isPath
      isSpecial
      isStorePath
      isString
      isStringLike
      isTest
      isValidPosixName
      typeOf
      ;
  };
in
  exports // {_rootAliases = exports;}
