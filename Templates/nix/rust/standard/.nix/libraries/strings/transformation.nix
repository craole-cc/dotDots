{lib, ...}: let
  __exports = {
    internal = {
      inherit
        capitalize
        indent
        normalize
        replaceAll
        toCamel
        toLower'
        toPascal
        toScreamingSnake
        toSnake
        toTitle
        toUpper'
        trim
        trimEnd
        trimStart
        ;
    };
    external = {
      capitalizeString = capitalize;
      toCamelCase = toCamel;
      toLowerCase = toLower';
      toPascalCase = toPascal;
      toScreamingSnakeCase = toScreamingSnake;
      toSnakeCase = toSnake;
      toTitleCase = toTitle;
      toUpperCase = toUpper';
      trimString = trim;
      trimStringEnd = trimEnd;
      trimStringStart = trimStart;
      replaceAllStrings = replaceAll;
      normalizeString = normalize;
    };
  };
  inherit
    (lib.lists)
    any
    genList
    head
    isList
    map
    tail
    toList
    ;
  inherit
    (lib.strings)
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
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  #? Internal: split a string into lowercase words on spaces, underscores, hyphens.
  _splitWords = s: splitString "-" (replaceStrings [" " "_"] ["-" "-"] (_normalizeSymbols (toLower s)));

  _symbolAliases = {
    "c++" = "cpp";
    "c#" = "csharp";
    ".net" = "dotnet";
    "objc" = "objectivec";
  };

  _normalizeSymbols = s: _symbolAliases.${s} or (replaceStrings ["++" "#" "."] ["p" "sharp" "-"] s);
  /**
  Convert a string or list of strings to lower case.

  # Type
  ```nix
  toLower' :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toLower' "FOO Bar"      # => "foo bar"
  toLower' ["FOO" "BAR"] # => ["foo" "bar"]
  ```
  */
  toLower' = input:
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr toLower input;

  /**
  Convert a string or list of strings to upper case.

  # Type
  ```nix
  toUpper' :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toUpper' "foo bar"      # => "FOO BAR"
  toUpper' ["foo" "bar"] # => ["FOO" "BAR"]
  ```
  */
  toUpper' = input:
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr toUpper input;

  /**
  Remove leading occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space. Strips repeatedly.

  # Type
  ```nix
  trimStart :: string | null -> string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  trimStart null "  foo bar"              # => "foo bar"
  trimStart "home:" "home:home:Pictures" # => "Pictures"
  trimStart null ["  a" "  b"]           # => ["a" "b"]
  ```
  */
  trimStart = chars: let
    c =
      if chars == null
      then " "
      else if !isString chars
      then throw msgs.chars
      else chars;
    go = s:
      if hasPrefix c s
      then go (removePrefix c s)
      else s;
  in
    input:
      if isList input && any isList input
      then throw msgs.nested
      else _applyStr go input;

  /**
  Remove trailing occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space. Strips repeatedly.

  # Type
  ```nix
  trimEnd :: string | null -> string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  trimEnd null "foo bar  "    # => "foo bar"
  trimEnd "!" "foo!!!"        # => "foo"
  trimEnd null ["a  " "b "]  # => ["a" "b"]
  ```
  */
  trimEnd = chars: let
    c =
      if chars == null
      then " "
      else if !isString chars
      then throw msgs.chars
      else chars;
    go = s:
      if hasSuffix c s
      then go (removeSuffix c s)
      else s;
  in
    input:
      if isList input && any isList input
      then throw msgs.nested
      else _applyStr go input;

  /**
  Remove leading and trailing occurrences of `chars` from a string or list of strings.

  Pass null to default to a single space.

  # Type
  ```nix
  trim :: string | null -> string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  trim null "  foo bar  "       # => "foo bar"
  trim "/" "/foo/bar/"          # => "foo/bar"
  trim null ["  a  " "  b  "]  # => ["a" "b"]
  ```
  */
  trim = chars: input: trimStart chars (trimEnd chars input);

  /**
  Replace all occurrences of substrings in a string or list of strings.

  Accepts either a single search/replace pair, or parallel lists.

  # Type
  ```nix
  replaceAll :: string | [string] -> string | [string] -> string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  replaceAll "foo" "bar" "foo foo"               # => "bar bar"
  replaceAll [" " "_"] ["-" "-"] "zen twilight"  # => "zen-twilight"
  replaceAll "a" "b" ["a" "cat"]                 # => ["b" "cbt"]
  ```
  */
  replaceAll = search: replace: let
    ss = toList search;
    rs = toList replace;
    msg = "nested lists are not supported in input";
  in
    input:
      if isList input && any isList input
      then throw msg
      else if isList ss && any isList ss
      then throw msg
      else if isList rs && any isList rs
      then throw msg
      else _applyStr (replaceStrings ss rs) input;

  /**
  Normalize a string or list of strings for fuzzy matching.

  Converts to lower case and replaces spaces/underscores with hyphens.

  # Type
  ```nix
  normalize :: string | [string] | null -> string | [string] | null
  ```

  # Examples
  ```nix
  normalize "Zen Twilight"               # => "zen-twilight"
  normalize "zen_twilight"               # => "zen-twilight"
  normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]
  normalize null                         # => null
  normalize []                           # => null
  ```
  */
  normalize = input:
    if isEmpty input
    then null
    else if isList input && any isList input
    then throw msgs.nested
    else _applyStr (s: replaceAll [" " "_"] ["-" "-"] (toLower s)) input;

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
  capitalize = input: let
    go = s:
      if s == ""
      then ""
      else toUpper (substring 0 1 s) + substring 1 (stringLength s) s;
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;

  /**
  Convert a string or list of strings to camelCase.

  Splits on spaces, underscores, and hyphens.

  # Type
  ```nix
  toCamel :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toCamel "foo bar"           # => "fooBar"
  toCamel "foo_bar_baz"       # => "fooBarBaz"
  toCamel ["foo bar" "a_b"]   # => ["fooBar" "aB"]
  ```
  */
  toCamel = input: let
    go = s: let
      words = _splitWords s;
    in
      head words + concatStringsSep "" (map capitalize (tail words));
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;

  /**
  Convert a string or list of strings to PascalCase.

  Splits on spaces, underscores, and hyphens.

  # Type
  ```nix
  toPascal :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toPascal "foo bar"           # => "FooBar"
  toPascal "foo_bar_baz"       # => "FooBarBaz"
  toPascal ["foo bar" "a_b"]   # => ["FooBar" "AB"]
  ```
  */
  toPascal = input: let
    go = s: concatStringsSep "" (map capitalize (_splitWords s));
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;

  /**
  Convert a string or list of strings to snake_case.

  Splits on spaces, underscores, and hyphens. All lowercase.

  # Type
  ```nix
  toSnake :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toSnake "Foo Bar"           # => "foo_bar"
  toSnake "fooBarBaz"         # => "foobarbaz"  (no camelCase splitting)
  toSnake ["Foo Bar" "A-B"]   # => ["foo_bar" "a_b"]
  ```
  */
  toSnake = input: let
    go = s: concatStringsSep "_" (_splitWords s);
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;

  /**
  Convert a string or list of strings to SCREAMING_SNAKE_CASE.

  Splits on spaces, underscores, and hyphens. All uppercase.

  # Type
  ```nix
  toScreamingSnake :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toScreamingSnake "foo bar"        # => "FOO_BAR"
  toScreamingSnake "fooBarBaz"      # => "FOOBARBAZ"
  toScreamingSnake ["foo" "bar"]    # => ["FOO" "BAR"]
  ```
  */
  toScreamingSnake = input: let
    go = s: toUpper (concatStringsSep "_" (_splitWords s));
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;

  /**
  Convert a string or list of strings to Title Case.

  Splits on spaces, underscores, and hyphens. Each word is capitalized
  and rejoined with a single space.

  # Type
  ```nix
  toTitle :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toTitle "foo bar"           # => "Foo Bar"
  toTitle "foo_bar_baz"       # => "Foo Bar Baz"
  toTitle "the-quick-fox"     # => "The Quick Fox"
  toTitle ["foo bar" "a_b"]   # => ["Foo Bar" "A B"]
  ```
  */
  toTitle = input: let
    go = s: concatStringsSep " " (map capitalize (_splitWords s));
  in
    if isList input && any isList input
    then throw msgs.nested
    else _applyStr go input;
in
  __exports.external
