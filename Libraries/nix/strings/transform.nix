{
  lib,
  _,
  ...
}: let
  inherit (_.strings.generators) toList;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.lists) isList map;
  inherit (lib.strings) hasPrefix hasSuffix removePrefix removeSuffix replaceStrings;

  # Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  /**
  Convert a string or list of strings to lower case.

  # Type
  ```nix
  toLower :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toLower "FOO Bar"      # => "foo bar"
  toLower ["FOO" "BAR"] # => ["foo" "bar"]
  ```
  */
  toLower = _applyStr lib.strings.toLower;

  /**
  Convert a string or list of strings to upper case.

  # Type
  ```nix
  toUpper :: string | [string] -> string | [string]
  ```

  # Examples
  ```nix
  toUpper "foo bar"      # => "FOO BAR"
  toUpper ["foo" "bar"] # => ["FOO" "BAR"]
  ```
  */
  toUpper = _applyStr lib.strings.toUpper;

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
      else chars;
    go = s:
      if hasPrefix c s
      then go (removePrefix c s)
      else s;
  in
    _applyStr go;

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
      else chars;
    go = s:
      if hasSuffix c s
      then go (removeSuffix c s)
      else s;
  in
    _applyStr go;

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
  trim = chars: input:
    trimStart chars (trimEnd chars input);

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
  in
    _applyStr (replaceStrings ss rs);

  /**
  Normalize an application or identifier name for fuzzy matching.

  Converts to lower case and replaces spaces/underscores with hyphens.

  # Type
  ```nix
  normalizeName :: string | null -> string | null
  ```

  # Examples
  ```nix
  normalizeName "Zen Twilight"  # => "zen-twilight"
  normalizeName "zen_twilight"  # => "zen-twilight"
  normalizeName null            # => null
  ```
  */
  normalizeName = value:
    if (value == null) || (value == [])
    then null
    else replaceAll [" " "_"] ["-" "-"] (lib.strings.toLower value);

  /**
  Normalize a single name or list of names for fuzzy matching.

  # Type
  ```nix
  normalizeNames :: string | [string | null] | null -> string | [string | null] | null
  ```

  # Examples
  ```nix
  normalizeNames "Zen Twilight"               # => "zen-twilight"
  normalizeNames ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]
  normalizeNames null                         # => null
  ```
  */
  normalizeNames = values:
    if (values == null) || (values == [])
    then null
    else if isList values
    then map normalizeName values
    else normalizeName values;
in {
  inherit
    toLower
    toUpper
    trim
    trimEnd
    trimStart
    replaceAll
    normalizeName
    normalizeNames
    ;

  _tests = runTests {
    toLower = {
      singleString = mkTest {
        desired = "foo bar";
        outcome = toLower "FOO Bar";
      };
      list = mkTest {
        desired = ["foo" "bar"];
        outcome = toLower ["FOO" "BAR"];
      };
    };
    toUpper = {
      singleString = mkTest {
        desired = "FOO BAR";
        outcome = toUpper "foo bar";
      };
      list = mkTest {
        desired = ["FOO" "BAR"];
        outcome = toUpper ["foo" "bar"];
      };
    };
    trimStart = {
      spaces = mkTest {
        desired = "foo bar";
        outcome = trimStart null "  foo bar";
      };
      customChar = mkTest {
        desired = "Pictures";
        outcome = trimStart "home:" "home:home:Pictures";
      };
      list = mkTest {
        desired = ["a" "b"];
        outcome = trimStart null ["  a" "  b"];
      };
    };
    trimEnd = {
      spaces = mkTest {
        desired = "foo bar";
        outcome = trimEnd null "foo bar  ";
      };
      customChar = mkTest {
        desired = "foo";
        outcome = trimEnd "!" "foo!!!";
      };
    };
    trim = {
      spaces = mkTest {
        desired = "foo bar";
        outcome = trim null "  foo bar  ";
      };
      customChar = mkTest {
        desired = "foo/bar";
        outcome = trim "/" "/foo/bar/";
      };
    };
    replaceAll = {
      singlePair = mkTest {
        desired = "bar bar";
        outcome = replaceAll "foo" "bar" "foo foo";
      };
      multiPair = mkTest {
        desired = "zen-twilight";
        outcome = replaceAll [" " "_"] ["-" "-"] "zen twilight";
      };
      list = mkTest {
        desired = ["b" "cbt"];
        outcome = replaceAll "a" "b" ["a" "cat"];
      };
    };
    normalizeName = {
      spaces = mkTest {
        desired = "zen-twilight";
        outcome = normalizeName "Zen Twilight";
      };
      underscores = mkTest {
        desired = "zen-twilight";
        outcome = normalizeName "zen_twilight";
      };
      nullInput = mkTest {
        desired = null;
        outcome = normalizeName null;
      };
    };
    normalizeNames = {
      single = mkTest {
        desired = "zen-twilight";
        outcome = normalizeNames "Zen Twilight";
      };
      list = mkTest {
        desired = ["zen-twilight" "zen-beta"];
        outcome = normalizeNames ["Zen Twilight" "zen_beta"];
      };
      nullInput = mkTest {
        desired = null;
        outcome = normalizeNames null;
      };
    };
  };
}
