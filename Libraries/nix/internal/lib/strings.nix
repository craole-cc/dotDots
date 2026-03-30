{lib, ...}: let
  __exports =
    {
      inherit
        access
        construction
        formatting
        predicates
        transformation
        ;
    }
    // access
    // construction
    // formatting
    // predicates
    // transformation
    // {};

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
  __exports
