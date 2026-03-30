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
        formatting
        predicates
        transformation
        ;
    };
    flattened =
      {}
      // access
      // construction
      // formatting
      // predicates
      // transformation
      // {};
  };

  access = {
    inherit
      (lib.strings)
      charToInt
      intToChar
      stringLength
      stringToCharacters
      substring
      splitString
      ;
  };

  construction = {
    inherit
      (lib.strings)
      concatImapStringsSep
      concatMapStrings
      concatStrings
      concatStringsSep
      optionalString
      ;
  };

  transformation = {
    inherit
      (lib.strings)
      escape
      escapeNixString
      escapeRegex
      escapeShellArg
      escapeShellArgs
      escapeXML
      normalizePath
      removePrefix
      removeSuffix
      replaceStrings
      toLower
      toUpper
      trim
      ;
  };

  formatting = {
    inherit
      (lib.strings)
      fixedWidthNumber
      fixedWidthString
      floatToString
      ;
  };

  predicates = {
    inherit
      (lib.strings)
      hasInfix
      hasPrefix
      hasSuffix
      isValidPosixName
      isString
      match
      split
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
