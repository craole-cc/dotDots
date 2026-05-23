{
  __moduleRef,
  _,
  ...
}: let
  functions = {
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
      trim'
      trimEnd
      trimStart
      wrap
      ;
  };
  aliases = {
    # capitalizeString = capitalize;
    toCamelCase = toCamel;
    toLowerCase = toLower';
    toPascalCase = toPascal;
    toScreamingSnakeCase = toScreamingSnake;
    toSnakeCase = toSnake;
    toTitleCase = toTitle;
    toUpperCase = toUpper';
    # trimString = trim;
    # trimStringEnd = trimEnd;
    # trimStringStart = trimStart;
    # replaceAllStrings = replaceAll;
    # normalizeString = normalize;
    quote = wrap;
  };
  __exports = {
    internal = functions // aliases;
    external =
      aliases
      // {
        capitalizeString = capitalize;
        toCamelCase = toCamel;
        toLowerCase = toLower';
        toPascalCase = toPascal;
        toScreamingSnakeCase = toScreamingSnake;
        toSnakeCase = toSnake;
        toTitleCase = toTitle;
        toUpperCase = toUpper';
        trimString = trim';
        trimStringEnd = trimEnd;
        trimStringStart = trimStart;
        replaceAllStrings = replaceAll;
        normalizeString = normalize;
        quoteString = wrap;
      };
  };
  _debug = mkModuleDebug __moduleRef;
  inherit (_debug) mkFn mkExample;

  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.lists.access) head tail;
  inherit (_.lists.construction) toList;
  inherit (_.debug.testing) mkTest;
  inherit (_.debug.assertions) withContext;
  inherit (_.debug.testing.runners) runTests;
  inherit (_.lists.construction) genList;
  inherit (_.lists.predicates) any;
  inherit (_.types.predicates) isAttrs isList isString;
  inherit
    (_.strings.transformation)
    removePrefix
    removeSuffix
    replaceStrings
    toLower
    toUpper
    ;
  inherit (_.strings.construction) concat splitString optionalString;
  inherit (_.strings.access) stringLength substring;
  inherit (_.strings.predicates) hasPrefix hasSuffix;
  inherit (_.content.emptiness) isEmpty;

  #? Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  #? Internal: split a string into lowercase words on spaces, underscores, hyphens.
  _splitWords = text:
    splitString "-" (
      replaceStrings [" " "_"] ["-" "-"]
      (_normalizeSymbols (toLower text))
    );

  _symbolAliases = {
    "c++" = "cpp";
    "c#" = "csharp";
    ".net" = "dotnet";
    "objc" = "objectivec";
  };

  _normalizeSymbols = text:
    _symbolAliases.${text} or (replaceStrings ["++" "#" "."] ["p" "sharp" "-"] text);

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
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toLower'";
            fn = toLower';
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string | [string]";
          example = mkExample {
            cmd = ''toLower' ["FOO" "BAR"]'';
            res = ''["foo" "bar"]'';
          };
          inherit input;
        }
      )
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
      throw (
        _debug.withDoc {
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
        }
      )
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
        throw (
          _debug.withLoc {
            function = mkFn {
              name = "trimStart";
              fn = trimStart;
            };
            message = "chars must be a string or null";
            input = chars;
          }
        )
      else chars;
    asStr = text:
      if hasPrefix c text
      then asStr (removePrefix c text)
      else text;
  in
    input:
      if isList input && any isList input
      then
        throw (
          _debug.withDoc {
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
          }
        )
      else _applyStr asStr input;

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
        throw (
          _debug.withLoc {
            function = mkFn {
              name = "trimEnd";
              fn = trimEnd;
            };
            message = "chars must be a string or null";
            input = chars;
          }
        )
      else chars;
    asStr = text:
      if hasSuffix c text
      then asStr (removeSuffix c text)
      else text;
  in
    input:
      if isList input && any isList input
      then
        throw (
          _debug.withDoc {
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
          }
        )
      else _applyStr asStr input;

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
  trim' = chars: input: trimStart chars (trimEnd chars input);

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
        throw (
          _debug.withDoc {
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
          }
        )
      else if isList ss && any isList ss
      then
        throw (
          _debug.withLoc {
            function = mkFn {
              name = "replaceAll";
              fn = replaceAll;
            };
            message = "nested lists are not supported in search";
            input = search;
          }
        )
      else if isList rs && any isList rs
      then
        throw (
          _debug.withLoc {
            function = mkFn {
              name = "replaceAll";
              fn = replaceAll;
            };
            message = "nested lists are not supported in replace";
            input = replace;
          }
        )
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
      throw (
        _debug.withDoc {
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
        }
      )
    else _applyStr (text: replaceAll [" " "_"] ["-" "-"] (toLower text)) input;

  indent = n: concat "" (genList (_: " ") n);

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
    asStr = text:
      if text == ""
      then ""
      else toUpper (substring 0 1 text) + substring 1 (stringLength text) text;
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
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
        }
      )
    else _applyStr asStr input;

  /**
  Convert a string or list of strings to camelCase.

  Splits on spaces, underscores, and hyphens.
  When given a list, treats elements as pre-split words and joins them.

  # Type
  ```nix
  toCamel :: string | [string] -> string
  ```

  # Examples
  ```nix
  toCamel "foo bar"                    # => "fooBar"
  toCamel "foo_bar_baz"                # => "fooBarBaz"
  toCamel ["registry" "of" "entry"]   # => "registryOfEntry"
  ```
  */
  toCamel = input: let
    asStr = text: let
      words = _splitWords text;
    in
      head words + concat "" (map capitalize (tail words));
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toCamel";
            fn = toCamel;
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string";
          example = mkExample {
            cmd = ''toCamel ["registry" "of" "entry"]'';
            res = ''"registryOfEntry"'';
          };
          inherit input;
        }
      )
    else if isList input
    then concat "" ([(head input)] ++ map capitalize (tail input))
    else asStr input;

  /**
  Convert a string or list of strings to PascalCase.

  Splits on spaces, underscores, and hyphens.
  When given a list, treats elements as pre-split words and joins them.

  # Type
  ```nix
  toPascal :: string | [string] -> string
  ```

  # Examples
  ```nix
  toPascal "foo bar"                   # => "FooBar"
  toPascal "foo_bar_baz"               # => "FooBarBaz"
  toPascal ["registry" "of" "entry"]  # => "RegistryOfEntry"
  ```
  */
  toPascal = input: let
    asStr = text: concat "" (map capitalize (_splitWords text));
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toPascal";
            fn = toPascal;
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string";
          example = mkExample {
            cmd = ''toPascal ["registry" "of" "entry"]'';
            res = ''"RegistryOfEntry"'';
          };
          inherit input;
        }
      )
    else if isList input
    then concat "" (map capitalize input)
    else asStr input;

  /**
  Convert a string or list of strings to snake_case.

  Splits on spaces, underscores, and hyphens. All lowercase.
  When given a list, treats elements as pre-split words and joins them.

  # Type
  ```nix
  toSnake :: string | [string] -> string
  ```

  # Examples
  ```nix
  toSnake "Foo Bar"                    # => "foo_bar"
  toSnake "fooBarBaz"                  # => "foobarbaz"  (no camelCase splitting)
  toSnake ["registry" "of" "entry"]   # => "registry_of_entry"
  ```
  */
  toSnake = input: let
    asStr = text: concat "_" (_splitWords text);
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toSnake";
            fn = toSnake;
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string";
          example = mkExample {
            cmd = ''toSnake ["registry" "of" "entry"]'';
            res = ''"registry_of_entry"'';
          };
          inherit input;
        }
      )
    else if isList input
    then concat "_" input
    else asStr input;

  /**
  Convert a string or list of strings to SCREAMING_SNAKE_CASE.

  Splits on spaces, underscores, and hyphens. All uppercase.
  When given a list, treats elements as pre-split words and joins them.

  # Type
  ```nix
  toScreamingSnake :: string | [string] -> string
  ```

  # Examples
  ```nix
  toScreamingSnake "foo bar"                   # => "FOO_BAR"
  toScreamingSnake "fooBarBaz"                 # => "FOOBARBAZ"
  toScreamingSnake ["registry" "of" "entry"]  # => "REGISTRY_OF_ENTRY"
  ```
  */
  toScreamingSnake = input: let
    asStr = text: toUpper (concat "_" (_splitWords text));
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toScreamingSnake";
            fn = toScreamingSnake;
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string";
          example = mkExample {
            cmd = ''toScreamingSnake ["registry" "of" "entry"]'';
            res = ''"REGISTRY_OF_ENTRY"'';
          };
          inherit input;
        }
      )
    else if isList input
    then toUpper (concat "_" input)
    else asStr input;

  /**
  Convert a string or list of strings to Title Case.

  Splits on spaces, underscores, and hyphens. Each word is capitalized
  and rejoined with a single space.
  When given a list, treats elements as pre-split words and joins them.

  # Type
  ```nix
  toTitle :: string | [string] -> string
  ```

  # Examples
  ```nix
  toTitle "foo bar"                    # => "Foo Bar"
  toTitle "foo_bar_baz"                # => "Foo Bar Baz"
  toTitle "the-quick-fox"              # => "The Quick Fox"
  toTitle ["registry" "of" "entry"]   # => "Registry Of Entry"
  ```
  */
  toTitle = input: let
    asStr = text: concat " " (map capitalize (_splitWords text));
  in
    if isList input && any isList input
    then
      throw (
        _debug.withDoc {
          function = mkFn {
            name = "toTitle";
            fn = toTitle;
          };
          message = "nested lists are not supported";
          signature = "string | [string] -> string";
          example = mkExample {
            cmd = ''toTitle ["registry" "of" "entry"]'';
            res = ''"Registry Of Entry"'';
          };
          inherit input;
        }
      )
    else if isList input
    then concat " " (map capitalize input)
    else asStr input;

  # wrap = {
  #   token ? "`",
  #   input,
  #   type ? "string",
  #   sep ? "",
  # }: let
  #   types = ["string" "list"];

  #   asList = token': input':
  #     map (item:
  #       concat "" [
  #         token'
  #         (toString item)
  #         token'
  #       ]) (toList input');

  #   asString = token': input': sep':
  #     concat sep' (asList token' (toString input'));
  # in
  #   assert withContext {
  #     name = concat "." ["strings" "construction" "wrap"];
  #     context = concat " " ["wrapping" "string" "values"];
  #     assertion = isIn type types;
  #     message = concat " " [
  #       "expected"
  #       (asString "`" "type" "")
  #       "to"
  #       "be"
  #       (asString "`" types " or ")
  #     ];
  #   };
  #     if type == "list"
  #     then asList token input
  #     else asString token input sep;
  wrap = value: let
    args =
      if isAttrs value
      then
        (
          if value ? input
          then value
          else if value ? text
          then value // {input = value.text;}
          else
            assert withContext {
              name = concat "." ["strings" "construction" "wrap"];
              context = concat " " ["validating" "wrap" "input"];
              assertion = false;
              message = "expected attrset to have an `input` or `text` key";
            }; null
        )
      else if isList value || isString value
      then {input = value;}
      else
        assert withContext {
          name = concat "." ["strings" "construction" "wrap"];
          context = concat " " ["validating" "wrap" "value"];
          assertion = false;
          message = "expected `value` to be a string, list, or attrset";
        }; null;

    input = assert withContext {
      name = concat "." ["strings" "construction" "wrap"];
      context = concat " " ["validating" "wrap" "input"];
      assertion = isNotEmpty args.input;
      message = "expected `input` to be a non-null value or a non-empty list";
    };
      args.input;

    token = let
      token' = args.token or "`";
    in
      assert withContext {
        name = concat "." ["strings" "construction" "wrap"];
        context = concat " " ["validating" "wrap" "token"];
        assertion = isString token' && token' != "";
        message = "expected `token` to be a non-empty string";
      }; token';

    delimiter = let
      sep =
        args.delimiter or (
          args.sep or (optionalString (isList args.input) " or ")
        );
    in
      assert withContext {
        name = concat "." ["strings" "construction" "wrap"];
        context = concat " " ["validating" "wrap" "delimiter"];
        assertion = isString sep;
        message = "expected `delimiter` to be a string";
      }; sep;

    rendered =
      map
      (item: concat "" [token (toString item) token])
      (toList input);
  in
    if isList input
    then concat delimiter rendered
    else head rendered;
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
          desired = [
            "foo"
            "bar"
          ];
          command = ''toLower ["FOO" "BAR"]'';
          outcome = toLower [
            "FOO"
            "BAR"
          ];
        };
      };
      toUpper = {
        singleString = mkTest {
          desired = "FOO BAR";
          command = ''toUpper "foo bar"'';
          outcome = toUpper "foo bar";
        };
        list = mkTest {
          desired = [
            "FOO"
            "BAR"
          ];
          command = ''toUpper ["foo" "bar"]'';
          outcome = toUpper [
            "foo"
            "bar"
          ];
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
          desired = [
            "a"
            "b"
          ];
          command = ''trimStart null ["  a" "  b"]'';
          outcome = trimStart null [
            "  a"
            "  b"
          ];
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
      trim' = {
        spaces = mkTest {
          desired = "foo bar";
          command = ''trim null "  foo bar  "'';
          outcome = trim' null "  foo bar  ";
        };
        customChar = mkTest {
          desired = "foo/bar";
          command = ''trim "/" "/foo/bar/"'';
          outcome = trim' "/" "/foo/bar/";
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
          desired = [
            "b"
            "cbt"
          ];
          command = ''replaceAll "a" "b" ["a" "cat"]'';
          outcome = replaceAll "a" "b" [
            "a"
            "cat"
          ];
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
          desired = [
            "zen-twilight"
            "zen-beta"
          ];
          command = ''normalize ["Zen Twilight" "zen_beta"]'';
          outcome = normalize [
            "Zen Twilight"
            "zen_beta"
          ];
        };
        nullInput = mkTest {
          desired = null;
          command = "normalize null";
          outcome = normalize null;
        };
        emptyInput = mkTest {
          desired = null;
          command = "normalize []";
          outcome = normalize [];
        };
      };
      toCamel = {
        singleString = mkTest {
          desired = "fooBar";
          command = ''toCamel "foo bar"'';
          outcome = toCamel "foo bar";
        };
        wordList = mkTest {
          desired = "registryOfEntry";
          command = ''toCamel ["registry" "of" "entry"]'';
          outcome = toCamel ["registry" "of" "entry"];
        };
      };
      toPascal = {
        singleString = mkTest {
          desired = "FooBar";
          command = ''toPascal "foo bar"'';
          outcome = toPascal "foo bar";
        };
        wordList = mkTest {
          desired = "RegistryOfEntry";
          command = ''toPascal ["registry" "of" "entry"]'';
          outcome = toPascal ["registry" "of" "entry"];
        };
      };
      toSnake = {
        singleString = mkTest {
          desired = "foo_bar";
          command = ''toSnake "Foo Bar"'';
          outcome = toSnake "Foo Bar";
        };
        wordList = mkTest {
          desired = "registry_of_entry";
          command = ''toSnake ["registry" "of" "entry"]'';
          outcome = toSnake ["registry" "of" "entry"];
        };
      };
      toScreamingSnake = {
        singleString = mkTest {
          desired = "FOO_BAR";
          command = ''toScreamingSnake "foo bar"'';
          outcome = toScreamingSnake "foo bar";
        };
        wordList = mkTest {
          desired = "REGISTRY_OF_ENTRY";
          command = ''toScreamingSnake ["registry" "of" "entry"]'';
          outcome = toScreamingSnake ["registry" "of" "entry"];
        };
      };
      toTitle = {
        singleString = mkTest {
          desired = "Foo Bar";
          command = ''toTitle "foo bar"'';
          outcome = toTitle "foo bar";
        };
        wordList = mkTest {
          desired = "Registry Of Entry";
          command = ''toTitle ["registry" "of" "entry"]'';
          outcome = toTitle ["registry" "of" "entry"];
        };
      };
    };
  }
