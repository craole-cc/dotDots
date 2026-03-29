{lib, ...}: {
  inherit
    (lib.strings)
    #~@ Basic Access
    stringLength
    substring
    splitString
    stringToCharacters
    charToInt
    intToChar
    #~@ Construction / Joining
    concatStrings
    concatStringsSep
    concatMapStrings
    concatImapStringsSep
    optionalString
    #~@ Transformation
    toLower
    toUpper
    trim
    replaceStrings
    removePrefix
    removeSuffix
    normalizePath
    escape
    escapeShellArg
    escapeShellArgs
    escapeXML
    escapeNixString
    escapeRegex
    #~@ Formatting
    fixedWidthString
    fixedWidthNumber
    floatToString
    #~@ Predicates & Searching
    hasPrefix
    hasSuffix
    hasInfix
    match
    split
    isString
    isBinaryString
    ;
}
