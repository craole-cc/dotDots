{ lib, ... }:
let
  inherit (lib.lists)
    any
    genList
    head
    isList
    map
    tail
    toList
    ;
  inherit (lib.strings)
    concatStringsSep
    hasPrefix
    isString
    hasSuffix
    removePrefix
    removeSuffix
    replaceStrings
    splitString
    stringLength
    substring
    toLower
    toUpper
    ;
  inherit (lib.trivial) isEmpty;

  msgs = {
    nested = "nested lists are not supported";
    chars = "chars must be a string or null";
  };

  #? Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input: if isList input then map fn input else fn input;

  #? Internal: split a string into lowercase words on spaces, underscores, hyphens.
  splitWords = s: splitString "-" (replaceStrings [ " " "_" ] [ "-" "-" ] (normalizeSymbols (toLower s)));

  normalizeSymbols =
    symbols:
    let
      aliases = {
        "c++" = "cpp";
        "c#" = "csharp";
        ".net" = "dotnet";
        "objc" = "objectivec";
      };
    in
    aliases.${symbols} or (replaceStrings [ "++" "#" "." ] [ "p" "sharp" "-" ] symbols);
  /**
    Convert a string or list of strings to lower case.

    # Type
    ```nix
    toLowerCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toLowerCase "FOO Bar"      # => "foo bar"
    toLowerCase ["FOO" "BAR"] # => ["foo" "bar"]
    ```
  */
  toLowerCase = input: if isList input && any isList input then throw msgs.nested else _applyStr toLower input;

  /**
    Convert a string or list of strings to upper case.

    # Type
    ```nix
    toUpperCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toUpperCase "foo bar"      # => "FOO BAR"
    toUpperCase ["foo" "bar"] # => ["FOO" "BAR"]
    ```
  */
  toUpperCase = input: if isList input && any isList input then throw msgs.nested else _applyStr toUpper input;

  /**
    Remove leading occurrences of `chars` from a string or list of strings.

    Pass null to default to a single space. Strips repeatedly.

    # Type
    ```nix
    trimStringStart :: string | null -> string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    trimStringStart null "  foo bar"              # => "foo bar"
    trimStringStart "home:" "home:home:Pictures" # => "Pictures"
    trimStringStart null ["  a" "  b"]           # => ["a" "b"]
    ```
  */
  trimStringStart =
    chars:
    let
      c =
        if chars == null then
          " "
        else if !isString chars then
          throw msgs.chars
        else
          chars;
      go = s: if hasPrefix c s then go (removePrefix c s) else s;
    in
    input: if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Remove trailing occurrences of `chars` from a string or list of strings.

    Pass null to default to a single space. Strips repeatedly.

    # Type
    ```nix
    trimStringEnd :: string | null -> string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    trimStringEnd null "foo bar  "    # => "foo bar"
    trimStringEnd "!" "foo!!!"        # => "foo"
    trimStringEnd null ["a  " "b "]  # => ["a" "b"]
    ```
  */
  trimStringEnd =
    chars:
    let
      c =
        if chars == null then
          " "
        else if !isString chars then
          throw msgs.chars
        else
          chars;
      go = s: if hasSuffix c s then go (removeSuffix c s) else s;
    in
    input: if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Remove leading and trailing occurrences of `chars` from a string or list of strings.

    Pass null to default to a single space.

    # Type
    ```nix
    trimString :: string | null -> string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    trimString null "  foo bar  "       # => "foo bar"
    trimString "/" "/foo/bar/"          # => "foo/bar"
    trimString null ["  a  " "  b  "]  # => ["a" "b"]
    ```
  */
  trimString = chars: input: trimStringStart chars (trimStringEnd chars input);

  /**
    Replace all occurrences of substrings in a string or list of strings.

    Accepts either a single search/replace pair, or parallel lists.

    # Type
    ```nix
    replaceAllStrings :: string | [string] -> string | [string] -> string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    replaceAllStrings "foo" "bar" "foo foo"               # => "bar bar"
    replaceAllStrings [" " "_"] ["-" "-"] "zen twilight"  # => "zen-twilight"
    replaceAllStrings "a" "b" ["a" "cat"]                 # => ["b" "cbt"]
    ```
  */
  replaceAllStrings =
    search: replace:
    let
      ss = toList search;
      rs = toList replace;
      msg = "nested lists are not supported in input";
    in
    input:
    if isList input && any isList input then
      throw msg
    else if isList ss && any isList ss then
      throw msg
    else if isList rs && any isList rs then
      throw msg
    else
      _applyStr (replaceStrings ss rs) input;

  /**
    Normalize a string or list of strings for fuzzy matching.

    Converts to lower case and replaces spaces/underscores with hyphens.

    # Type
    ```nix
    normalizeString :: string | [string] | null -> string | [string] | null
    ```

    # Examples
    ```nix
    normalizeString "Zen Twilight"               # => "zen-twilight"
    normalizeString "zen_twilight"               # => "zen-twilight"
    normalizeString ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]
    normalizeString null                         # => null
    normalizeString []                           # => null
    ```
  */
  normalizeString =
    input:
    if isEmpty input then
      null
    else if isList input && any isList input then
      throw msgs.nested
    else
      _applyStr (s: replaceAllStrings [ " " "_" ] [ "-" "-" ] (toLower s)) input;

  indent = n: concatStringsSep "" (genList (_: " ") n);

  /**
    Capitalize the first character of a string or list of strings.

    The rest of the string is left unchanged. Use `toLower` first
    if you want true Title Word behavior.

    # Type
    ```nix
    capitalize :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    capitalize "foo bar"      # => "Foo bar"
    capitalize "name"         # => "Name"
    capitalize ["foo" "bar"]  # => ["Foo" "Bar"]
    ```
  */
  capitalize =
    input:
    let
      go = s: if s == "" then "" else toUpper (substring 0 1 s) + substring 1 (stringLength s) s;
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Convert a string or list of strings to camelCase.

    Splits on spaces, underscores, and hyphens.

    # Type
    ```nix
    toCamelCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toCamelCase "foo bar"           # => "fooBar"
    toCamelCase "foo_bar_baz"       # => "fooBarBaz"
    toCamelCase ["foo bar" "a_b"]   # => ["fooBar" "aB"]
    ```
  */
  toCamelCase =
    input:
    let
      go =
        s:
        let
          words = splitWords s;
        in
        head words + concatStringsSep "" (map capitalize (tail words));
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Convert a string or list of strings to PascalCase.

    Splits on spaces, underscores, and hyphens.

    # Type
    ```nix
    toPascalCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toPascalCase "foo bar"           # => "FooBar"
    toPascalCase "foo_bar_baz"       # => "FooBarBaz"
    toPascalCase ["foo bar" "a_b"]   # => ["FooBar" "AB"]
    ```
  */
  toPascalCase =
    input:
    let
      go = s: concatStringsSep "" (map capitalize (splitWords s));
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Convert a string or list of strings to snake_case.

    Splits on spaces, underscores, and hyphens. All lowercase.

    # Type
    ```nix
    toSnakeCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toSnakeCase "Foo Bar"           # => "foo_bar"
    toSnakeCase "fooBarBaz"         # => "foobarbaz"  (no camelCase splitting)
    toSnakeCase ["Foo Bar" "A-B"]   # => ["foo_bar" "a_b"]
    ```
  */
  toSnakeCase =
    input:
    let
      go = s: concatStringsSep "_" (splitWords s);
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Convert a string or list of strings to SCREAMING_SNAKE_CASE.

    Splits on spaces, underscores, and hyphens. All uppercase.

    # Type
    ```nix
    toScreamingSnakeCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toScreamingSnakeCase "foo bar"        # => "FOO_BAR"
    toScreamingSnakeCase "fooBarBaz"      # => "FOOBARBAZ"
    toScreamingSnakeCase ["foo" "bar"]    # => ["FOO" "BAR"]
    ```
  */
  toScreamingSnakeCase =
    input:
    let
      go = s: toUpper (concatStringsSep "_" (splitWords s));
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;

  /**
    Convert a string or list of strings to Title Case.

    Splits on spaces, underscores, and hyphens. Each word is capitalized
    and rejoined with a single space.

    # Type
    ```nix
    toTitleCase :: string | [string] -> string | [string]
    ```

    # Examples
    ```nix
    toTitleCase "foo bar"           # => "Foo Bar"
    toTitleCase "foo_bar_baz"       # => "Foo Bar Baz"
    toTitleCase "the-quick-fox"     # => "The Quick Fox"
    toTitleCase ["foo bar" "a_b"]   # => ["Foo Bar" "A B"]
    ```
  */
  toTitleCase =
    input:
    let
      go = s: concatStringsSep " " (map capitalize (splitWords s));
    in
    if isList input && any isList input then throw msgs.nested else _applyStr go input;
in
{
  inherit
    capitalize
    indent
    normalizeString
    normalizeSymbols
    replaceAllStrings
    splitWords
    toCamelCase
    toLowerCase
    toPascalCase
    toScreamingSnakeCase
    toSnakeCase
    toTitleCase
    toUpperCase
    trimString
    trimStringEnd
    trimStringStart
    ;
  capitalizeString = capitalize;
  indentString = indent;
}
