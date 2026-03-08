{
  lib,
  _,
  library,
  __moduleNamespacePath,
  ...
}: let
  inherit (lib.lists) isList map any;
  inherit
    (lib.strings)
    hasPrefix
    hasSuffix
    isString
    removePrefix
    removeSuffix
    replaceStrings
    toLower
    toUpper
    ;
  inherit (_.strings.generators) toList;
  inherit (_.trivial.tests) mkTest runTests;

  _debug = _.trivial.debug.mkModuleDebug {
    inherit library;
    namespace = __moduleNamespacePath;
  };

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
  toLower' = input:
    if isList input && any isList input
    then
      throw (_debug.traceDoc {
        function = "toLower";
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        inherit input;
      })
    else _applyStr toLower input;

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
  toUpper' = input:
    if isList input && any isList input
    then
      throw (_debug.traceDoc {
        function = "toUpper";
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        inherit input;
      })
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
      then
        throw (_debug.traceLoc {
          function = "trimStart";
          message = "chars must be a string or null";
          input = chars;
        })
      else chars;
    go = s:
      if hasPrefix c s
      then go (removePrefix c s)
      else s;
  in
    input:
      if isList input && any isList input
      then
        throw (_debug.traceDoc {
          function = "trimStart";
          message = "nested lists are not supported";
          signature = "string | null -> string | [string] -> string | [string]";
          inherit input;
        })
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
      then
        throw (_debug.traceLoc {
          function = "trimEnd";
          message = "chars must be a string or null";
          input = chars;
        })
      else chars;
    go = s:
      if hasSuffix c s
      then go (removeSuffix c s)
      else s;
  in
    input:
      if isList input && any isList input
      then
        throw (_debug.traceDoc {
          function = "trimEnd";
          message = "nested lists are not supported";
          signature = "string | null -> string | [string] -> string | [string]";
          inherit input;
        })
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
    input:
      if isList input && any isList input
      then
        throw (_debug.traceDoc {
          function = "replaceAll";
          message = "nested lists are not supported in input";
          signature = "string | [string] -> string | [string] -> string | [string] -> string | [string]";
          inherit input;
        })
      else if isList ss && any isList ss
      then
        throw (_debug.traceLoc {
          function = "replaceAll";
          message = "nested lists are not supported in search";
          input = search;
        })
      else if isList rs && any isList rs
      then
        throw (_debug.traceLoc {
          function = "replaceAll";
          message = "nested lists are not supported in replace";
          input = replace;
        })
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
    if (input == null) || (input == [])
    then null
    else if isList input && any isList input
    then let
      function = "normalize";
      message = "nested lists are not supported";
      signature = ''string | [string] | null -> string | [string] | null'';
      example = ''normalize ["Zen Twilight" "zen_beta"] |=> ["zen-twilight" "zen-beta"]'';
    in
      # throw (_debug.withDoc {inherit input function message signature example;})
      throw (_debug.traceDoc {inherit input function message signature example;})
    # _debug.errorDoc {inherit input function message signature example;}
    # _debug.traceDoc {inherit input function message signature example;}
    # _debug.throwDoc {inherit input function message signature example;}
    # _debug.throwLoc {inherit input function message;}
    else
      _applyStr
      (s: replaceAll [" " "_"] ["-" "-"] (toLower' s))
      input;
in {
  inherit
    trim
    trimEnd
    trimStart
    replaceAll
    normalize
    ;
  toLower = toLower';
  toUpper = toUpper';

  _rootAliases = {
    toLowercase = toLower';
    toUppercase = toUpper';
    trimString = trim;
    trimStringStart = trimStart;
    trimStringEnd = trimEnd;
    replaceAllStrings = replaceAll;
    normalizeString = normalize;
  };

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
    normalize = {
      spaces = mkTest {
        desired = "zen-twilight";
        outcome = normalize "Zen Twilight";
      };
      underscores = mkTest {
        desired = "zen-twilight";
        outcome = normalize "zen_twilight";
      };
      list = mkTest {
        desired = ["zen-twilight" "zen-beta"];
        outcome = normalize ["Zen Twilight" "zen_beta"];
      };
      nullInput = mkTest {
        desired = null;
        outcome = normalize null;
      };
      emptyInput = mkTest {
        desired = null;
        outcome = normalize [];
      };
    };
  };
}
