{
  __moduleRef,
  _,
  lib,
  ...
}: let
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
  _debug = mkModuleDebug __moduleRef;
  inherit (_debug) mkFn mkExample;

  inherit (_.debug.module) mkModuleDebug;
  inherit (_.lists.construction) toList;
  inherit (_.debug.testing.assertions) mkTest;
  inherit (_.debug.testing.runners) runTests;
  inherit (_.types.predicates) isList isString;
  inherit
    (_.strings.transformation)
    removePrefix
    removeSuffix
    replaceStrings
    splitString
    toLower
    toUpper
    ;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.access) stringLength substring;
  inherit (_.strings.predicates) hasPrefix hasSuffix;
  inherit (_.content.empty) isEmpty;
  inherit (lib.lists) any genList map;

  #? Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  #? Internal: split a string into lowercase words on spaces, underscores, hyphens.
  _splitWords = s:
    splitString "-" (
      replaceStrings [" " "_"] ["-" "-"]
      (_normalizeSymbols (toLower s))
    );

  _symbolAliases = {
    "c++" = "cpp";
    "c#" = "csharp";
    ".net" = "dotnet";
    "objc" = "objectivec";
  };

  _normalizeSymbols = s:
    _symbolAliases.${
      s
    } or (
      replaceStrings
      ["++" "#" "."]
      ["p" "sharp" "-"]
      s
    );
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
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toLower";
          fn = toLower;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toLower ["FOO" "BAR"]'';
          res = ''["foo" "bar"]'';
        };
        inherit input;
      })
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
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toUpper";
          fn = toUpper;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toUpper ["foo" "bar"]'';
          res = ''["FOO" "BAR"]'';
        };
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
        throw (_debug.withLoc {
          function = mkFn {
            name = "trimStart";
            fn = trimStart;
          };
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
        throw (_debug.withDoc {
          function = mkFn {
            name = "trimStart";
            fn = trimStart;
          };
          message = "nested lists are not supported";
          signature = "string | null -> string | [string] -> string | [string]";
          example = mkExample {
            cmd = ''trimStart null ["  foo" "  bar"]'';
            res = ''["foo" "bar"]'';
          };
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
        throw (_debug.withLoc {
          function = mkFn {
            name = "trimEnd";
            fn = trimEnd;
          };
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
        throw (_debug.withDoc {
          function = mkFn {
            name = "trimEnd";
            fn = trimEnd;
          };
          message = "nested lists are not supported";
          signature = "string | null -> string | [string] -> string | [string]";
          example = mkExample {
            cmd = ''trimEnd null ["foo  " "bar  "]'';
            res = ''["foo" "bar"]'';
          };
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
        throw (_debug.withDoc {
          function = mkFn {
            name = "replaceAll";
            fn = replaceAll;
          };
          message = "nested lists are not supported in input";
          signature = "string | [string] -> string | [string] -> string | [string] -> string | [string]";
          example = mkExample {
            cmd = ''replaceAll " " "-" ["foo bar" "baz qux"]'';
            res = ''["foo-bar" "baz-qux"]'';
          };
          inherit input;
        })
      else if isList ss && any isList ss
      then
        throw (_debug.withLoc {
          function = mkFn {
            name = "replaceAll";
            fn = replaceAll;
          };
          message = "nested lists are not supported in search";
          input = search;
        })
      else if isList rs && any isList rs
      then
        throw (_debug.withLoc {
          function = mkFn {
            name = "replaceAll";
            fn = replaceAll;
          };
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
    if isEmpty input
    then null
    else if isList input && any isList input
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "normalize";
          fn = normalize;
        };
        message = "nested lists are not supported";
        signature = "string | [string] | null -> string | [string] | null";
        example = mkExample {
          cmd = ''normalize ["Zen Twilight" "zen_beta"]'';
          res = ''["zen-twilight" "zen-beta"]'';
        };
        inherit input;
      })
    else
      _applyStr
      (s: replaceAll [" " "_"] ["-" "-"] (toLower s))
      input;

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
      else
        toUpper (substring 0 1 s)
        + substring 1 (stringLength s) s;
  in
    if isList input && any isList input
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "capitalize";
          fn = capitalize;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''capitalize ["foo" "bar"]'';
          res = ''["Foo" "Bar"]'';
        };
        inherit input;
      })
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
      builtins.head words
      + concatStringsSep "" (map capitalize (builtins.tail words));
  in
    if isList input && any isList input
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toCamel";
          fn = toCamel;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toCamel ["foo bar" "baz_qux"]'';
          res = ''["fooBar" "bazQux"]'';
        };
        inherit input;
      })
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
    go = s:
      concatStringsSep "" (map capitalize (_splitWords s));
  in
    if isList input && any isList input
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toPascal";
          fn = toPascal;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toPascal ["foo bar" "baz_qux"]'';
          res = ''["FooBar" "BazQux"]'';
        };
        inherit input;
      })
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
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toSnake";
          fn = toSnake;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toSnake ["Foo Bar" "baz-qux"]'';
          res = ''["foo_bar" "baz_qux"]'';
        };
        inherit input;
      })
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
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toScreamingSnake";
          fn = toScreamingSnake;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toScreamingSnake ["foo bar" "baz_qux"]'';
          res = ''["FOO_BAR" "BAZ_QUX"]'';
        };
        inherit input;
      })
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
    go = s:
      concatStringsSep " " (map capitalize (_splitWords s));
  in
    if isList input && any isList input
    then
      throw (_debug.withDoc {
        function = mkFn {
          name = "toTitle";
          fn = toTitle;
        };
        message = "nested lists are not supported";
        signature = "string | [string] -> string | [string]";
        example = mkExample {
          cmd = ''toTitle ["foo bar" "baz_qux"]'';
          res = ''["Foo Bar" "Baz Qux"]'';
        };
        inherit input;
      })
    else _applyStr go input;
in
  __exports.internal
  // {
    __rootAliases = __exports.external;

    __tests = runTests {
      toLower = {
        singleString = mkTest {
          desired = "foo bar";
          command = ''toLower "FOO Bar"'';
          outcome = toLower "FOO Bar";
        };
        list = mkTest {
          desired = ["foo" "bar"];
          command = ''toLower ["FOO" "BAR"]'';
          outcome = toLower ["FOO" "BAR"];
        };
      };
      toUpper = {
        singleString = mkTest {
          desired = "FOO BAR";
          command = ''toUpper "foo bar"'';
          outcome = toUpper "foo bar";
        };
        list = mkTest {
          desired = ["FOO" "BAR"];
          command = ''toUpper ["foo" "bar"]'';
          outcome = toUpper ["foo" "bar"];
        };
      };
      trimStart = {
        spaces = mkTest {
          desired = "foo bar";
          command = ''trimStart null "  foo bar"'';
          outcome = trimStart null "  foo bar";
        };
        customChar = mkTest {
          desired = "Pictures";
          command = ''trimStart "home:" "home:home:Pictures"'';
          outcome = trimStart "home:" "home:home:Pictures";
        };
        list = mkTest {
          desired = ["a" "b"];
          command = ''trimStart null ["  a" "  b"]'';
          outcome = trimStart null ["  a" "  b"];
        };
      };
      trimEnd = {
        spaces = mkTest {
          desired = "foo bar";
          command = ''trimEnd null "foo bar  "'';
          outcome = trimEnd null "foo bar  ";
        };
        customChar = mkTest {
          desired = "foo";
          command = ''trimEnd "!" "foo!!!"'';
          outcome = trimEnd "!" "foo!!!";
        };
      };
      trim = {
        spaces = mkTest {
          desired = "foo bar";
          command = ''trim null "  foo bar  "'';
          outcome = trim null "  foo bar  ";
        };
        customChar = mkTest {
          desired = "foo/bar";
          command = ''trim "/" "/foo/bar/"'';
          outcome = trim "/" "/foo/bar/";
        };
      };
      replaceAll = {
        singlePair = mkTest {
          desired = "bar bar";
          command = ''replaceAll "foo" "bar" "foo foo"'';
          outcome = replaceAll "foo" "bar" "foo foo";
        };
        multiPair = mkTest {
          desired = "zen-twilight";
          command = ''replaceAll [" " "_"] ["-" "-"] "zen twilight"'';
          outcome = replaceAll [" " "_"] ["-" "-"] "zen twilight";
        };
        list = mkTest {
          desired = ["b" "cbt"];
          command = ''replaceAll "a" "b" ["a" "cat"]'';
          outcome = replaceAll "a" "b" ["a" "cat"];
        };
      };
      normalize = {
        spaces = mkTest {
          desired = "zen-twilight";
          command = ''normalize "Zen Twilight"'';
          outcome = normalize "Zen Twilight";
        };
        underscores = mkTest {
          desired = "zen-twilight";
          command = ''normalize "zen_twilight"'';
          outcome = normalize "zen_twilight";
        };
        list = mkTest {
          desired = ["zen-twilight" "zen-beta"];
          command = ''normalize ["Zen Twilight" "zen_beta"]'';
          outcome = normalize ["Zen Twilight" "zen_beta"];
        };
        nullInput = mkTest {
          desired = null;
          command = ''normalize null'';
          outcome = normalize null;
        };
        emptyInput = mkTest {
          desired = null;
          command = ''normalize []'';
          outcome = normalize [];
        };
      };
    };
  }
