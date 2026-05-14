{
  lib,
  flatten ? false,
  ...
}:
let
  __exports = {
    namespaced = {
      inherit
        access
        construction
        predicates
        transformation
        ;
    };
    flattened = { } // access // construction // predicates // transformation // { };
  };

  inherit (lib) strings;

  access = {
    inherit (strings)
      match
      split
      stringLength
      stringToCharacters
      substring
      ;
  };

  construction = {
    inherit (strings)
      charToInt
      concatImapStringsSep
      concatMapStringsSep
      concatMapStrings
      concatStrings
      concatStringsSep
      fixedWidthNumber
      fixedWidthString
      floatToString
      optionalString
      ;
  };

  transformation = {
    inherit (strings)
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
      splitString
      toLower
      toUpper
      trim
      ;
  };

  predicates = {
    inherit (strings)
      hasInfix
      hasPrefix
      hasSuffix
      isString
      isValidPosixName
      ;
  };
in
if flatten then __exports.namespaced // __exports.flattened else __exports.namespaced
