{
  lib,
  _,
  ...
}: let
  /**
  Check if a string contains a substring.

  # Type
  contains :: string -> string -> bool

  # Arguments
  - `substring`: The substring to search for
  - `string`: The string to search in

  # Returns
  True if the substring is found, false otherwise

  # Examples
  contains "foo" "foobar"  # true
  contains "bar" "foobar"  # true
  contains "baz" "foobar"  # false
  */
  contains = lib.strings.hasInfix;

  /**
  Check if a string contains any of the given patterns.

  # Type
  containsAny :: [string] -> string -> bool

  # Arguments
  - `patterns`: List of substrings to search for
  - `string`: The string to search in

  # Returns
  True if any pattern is found, false otherwise

  # Examples
  containsAny ["foo", "bar"] "foobar"  # true
  containsAny ["baz", "qux"] "foobar"  # false
  */
  containsAny = patterns: input:
    builtins.any (pattern: lib.strings.hasInfix pattern input) patterns;

  /**
  Check if a string starts with a prefix.

  # Type
  startsWith :: string -> string -> bool

  # Arguments
  - `prefix`: The prefix to check
  - `string`: The string to check

  # Returns
  True if the string starts with the prefix, false otherwise

  # Examples
  startsWith "foo" "foobar"  # true
  startsWith "bar" "foobar"  # false
  */
  startsWith = lib.strings.hasPrefix;

  /**
  Check if a string ends with a suffix.

  # Type
  endsWith :: string -> string -> bool

  # Arguments
  - `suffix`: The suffix to check
  - `string`: The string to check

  # Returns
  True if the string ends with the suffix, false otherwise

  # Examples
  endsWith "bar" "foobar"  # true
  endsWith "foo" "foobar"  # false
  */
  endsWith = lib.strings.hasSuffix;

  /**
  Convert a string to lower case.

  # Type
  toLower :: string -> string

  # Arguments
  - `string`: The string to convert

  # Returns
  The string in lower case

  # Examples
  toLower "FOO Bar"  # "foo bar"
  */
  toLower = lib.strings.toLower;

  /**
  Convert a string to upper case.

  # Type
  toUpper :: string -> string

  # Arguments
  - `string`: The string to convert

  # Returns
  The string in upper case

  # Examples
  toUpper "foo bar"  # "FOO BAR"
  */
  toUpper = lib.strings.toUpper;

  /**
  Remove characters from the start and end of a string.

  # Type
  trim :: string -> string -> string

  # Arguments
  - `string`: The string to trim

  # Returns
  The trimmed string

  # Examples
  trim "  foo bar  "  # "foo bar"
  */
  trim = lib.strings.trim;

  /**
  Remove characters from the start of a string.

  # Type
  trimStart :: string -> string -> string

  # Arguments
  - `string`: The string to trim

  # Returns
  The string with leading characters removed

  # Examples
  trimStart "  foo bar"  # "foo bar"
  */
  trimStart = lib.strings.removePrefix;

  /**
  Remove characters from the end of a string.

  # Type
  trimEnd :: string -> string -> string

  # Arguments
  - `string`: The string to trim

  # Returns
  The string with trailing characters removed

  # Examples
  trimEnd "foo bar  "  # "foo bar"
  */
  trimEnd = string: let
    reversed = lib.strings.concatStrings (lib.lists.reverseList (lib.strings.stringToCharacters string));
    trimmed = lib.strings.removePrefix " " reversed;
  in
    lib.strings.concatStrings (lib.lists.reverseList (lib.strings.stringToCharacters trimmed));

  /**
  Replace all occurrences of a substring with another.

  # Type
  replaceAll :: string -> string -> string -> string

  # Arguments
  - `search`: The substring to replace
  - `replace`: The string to replace with
  - `string`: The original string

  # Returns
  The string with all occurrences replaced

  # Examples
  replaceAll "foo" "bar" "foo foo foo"  # "bar bar bar"
  */
  replaceAll = search: replace: string:
    lib.strings.replaceStrings [search] [replace] string;

  /**
  Split a string by a delimiter.

  # Type
  split :: string -> string -> [string]

  # Arguments
  - `delimiter`: The delimiter to split on
  - `string`: The string to split

  # Returns
  List of substrings

  # Examples
  split "," "a,b,c"  # ["a", "b", "c"]
  */
  split = lib.strings.splitString;

  /**
  Join a list of strings with a delimiter.

  # Type
  join :: string -> [string] -> string

  # Arguments
  - `delimiter`: The delimiter to join with
  - `strings`: List of strings to join

  # Returns
  The joined string

  # Examples
  join "," ["a", "b", "c"]  # "a,b,c"
  */
  join = lib.strings.concatStringsSep;

  /**
  Check if a string is empty.

  # Type
  isEmpty :: string -> bool

  # Arguments
  - `string`: The string to check

  # Returns
  True if the string is empty or null, false otherwise

  # Examples
  isEmpty ""  # true
  isEmpty null  # true
  isEmpty "foo"  # false
  */
  isEmpty = str: str == "" || str == null;

  /**
  Check if a string is not empty.

  # Type
  isNotEmpty :: string -> bool

  # Arguments
  - `string`: The string to check

  # Returns
  True if the string is not empty and not null, false otherwise

  # Examples
  isNotEmpty "foo"  # true
  isNotEmpty ""  # false
  isNotEmpty null  # false
  */
  isNotEmpty = str: str != "" && str != null;
in {
  inherit
    contains
    containsAny
    startsWith
    endsWith
    toLower
    toUpper
    trim
    trimStart
    trimEnd
    replaceAll
    split
    join
    isEmpty
    isNotEmpty
    ;
  inherit (_) normalizeFlakePath;
}
