# values/fallback.nix
#
# Fallback and defaulting functions for missing or empty values.
{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_.contents.empty) isEmpty;
  inherit (lib.lists) findFirst;

  /**
  Return `value` if non-empty, otherwise `default`.

  The primary defaulting function — covers null, `""`, `[]`, and `{}`.

  # Type
  ```nix
  orDefault :: { value :: a, default :: a } -> a
  ```

  # Examples
  ```nix
  orDefault { value = "hello"; default = "fallback"; }  # => "hello"
  orDefault { value = null;    default = "fallback"; }  # => "fallback"
  orDefault { value = "";      default = "fallback"; }  # => "fallback"
  orDefault { value = 0;       default = 42;         }  # => 0     (zero is not empty)
  orDefault { value = false;   default = true;       }  # => false (false is not empty)
  ```
  */
  orDefault = {
    value,
    default,
  }:
    if isEmpty value
    then default
    else value;

  /**
  Return `value` if not null, otherwise `default`.

  Stricter than `orDefault` — only guards against null. Use when you need to
  preserve empty strings, lists, or attrsets.

  # Type
  ```nix
  orNull :: { value :: a, default :: a } -> a
  ```

  # Examples
  ```nix
  orNull { value = null; default = "fallback"; }  # => "fallback"
  orNull { value = "";   default = "fallback"; }  # => ""  (empty string preserved)
  orNull { value = [];   default = "fallback"; }  # => []  (empty list preserved)
  ```
  */
  orNull = {
    value,
    default,
  }:
    if value == null
    then default
    else value;

  /**
  Return the first non-empty value from a list, or null if all are empty.

  Single-arg so stays curried — the list is the whole input.

  # Type
  ```nix
  firstNonEmpty :: [a] -> a | null
  ```

  # Examples
  ```nix
  firstNonEmpty ["" null "hello" "world"]  # => "hello"
  firstNonEmpty [null "" {} []]            # => null

  value = firstNonEmpty [
    (env.CUSTOM_VALUE or null)
    (config.userValue  or null)
    "built-in-default"
  ];
  ```
  */
  firstNonEmpty = findFirst (v: !isEmpty v) null;

  /**
  Apply `fn` to `value` if non-empty, otherwise return `default`.

  # Type
  ```nix
  mapOrDefault :: { fn :: (a -> b), value :: a, default :: b } -> b
  ```

  # Examples
  ```nix
  mapOrDefault { fn = x: x + 1;    value = 5;    default = 0;   }  # => 6
  mapOrDefault { fn = x: x + 1;    value = null; default = 0;   }  # => 0
  mapOrDefault { fn = s: s + "!";  value = "";   default = "?"; }  # => "?"
  ```
  */
  mapOrDefault = {
    fn,
    value,
    default,
  }:
    if isEmpty value
    then default
    else fn value;

  /**
  Apply `fn` to `value` if not null, otherwise return `default`.

  Like `mapOrDefault` but with a null-only guard — empty strings and lists
  are still passed to `fn`.

  # Type
  ```nix
  mapOrNull :: { fn :: (a -> b), value :: a, default :: b } -> b
  ```

  # Examples
  ```nix
  mapOrNull { fn = s: s + "!"; value = null; default = "?"; }  # => "?"
  mapOrNull { fn = s: s + "!"; value = "";   default = "?"; }  # => "!"  (empty string transformed)
  ```
  */
  mapOrNull = {
    fn,
    value,
    default,
  }:
    if value == null
    then default
    else fn value;

  exports = {inherit orDefault orNull firstNonEmpty mapOrDefault mapOrNull;};
in
  exports
  // {
    _rootAliases = exports;

    _tests = runTests {
      orDefault = {
        returnsValueWhenNonEmpty = mkTest {
          desired = "hello";
          command = ''orDefault { value = "hello"; default = "fallback"; }'';
          outcome = orDefault {
            value = "hello";
            default = "fallback";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "fallback";
          command = ''orDefault { value = null; default = "fallback"; }'';
          outcome = orDefault {
            value = null;
            default = "fallback";
          };
        };
        returnsDefaultForEmptyString = mkTest {
          desired = "fallback";
          command = ''orDefault { value = ""; default = "fallback"; }'';
          outcome = orDefault {
            value = "";
            default = "fallback";
          };
        };
        returnsDefaultForWhitespace = mkTest {
          desired = "fallback";
          command = ''orDefault { value = "  "; default = "fallback"; }'';
          outcome = orDefault {
            value = "  ";
            default = "fallback";
          };
        };
        returnsDefaultForEmptyList = mkTest {
          desired = "fallback";
          command = ''orDefault { value = []; default = "fallback"; }'';
          outcome = orDefault {
            value = [];
            default = "fallback";
          };
        };
        returnsDefaultForEmptyAttrs = mkTest {
          desired = "fallback";
          command = ''orDefault { value = {}; default = "fallback"; }'';
          outcome = orDefault {
            value = {};
            default = "fallback";
          };
        };
        zeroIsNotEmpty = mkTest {
          desired = 0;
          command = "orDefault { value = 0; default = 42; }";
          outcome = orDefault {
            value = 0;
            default = 42;
          };
        };
        falseIsNotEmpty = mkTest {
          desired = false;
          command = "orDefault { value = false; default = true; }";
          outcome = orDefault {
            value = false;
            default = true;
          };
        };
      };

      orNull = {
        returnsValueWhenNonNull = mkTest {
          desired = "hello";
          command = ''orNull { value = "hello"; default = "fallback"; }'';
          outcome = orNull {
            value = "hello";
            default = "fallback";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "fallback";
          command = ''orNull { value = null; default = "fallback"; }'';
          outcome = orNull {
            value = null;
            default = "fallback";
          };
        };
        preservesEmptyString = mkTest {
          desired = "";
          command = ''orNull { value = ""; default = "fallback"; }'';
          outcome = orNull {
            value = "";
            default = "fallback";
          };
        };
        preservesEmptyList = mkTest {
          desired = [];
          command = "orNull { value = []; default = [1]; }";
          outcome = orNull {
            value = [];
            default = [1];
          };
        };
        preservesEmptyAttrs = mkTest {
          desired = {};
          command = "orNull { value = {}; default = { a = 1; }; }";
          outcome = orNull {
            value = {};
            default = {a = 1;};
          };
        };
      };

      firstNonEmpty = {
        returnsFirstNonEmpty = mkTest {
          desired = "hello";
          command = ''firstNonEmpty ["" null "hello" "world"]'';
          outcome = firstNonEmpty ["" null "hello" "world"];
        };
        skipsNullAndEmpty = mkTest {
          desired = "hello";
          command = ''firstNonEmpty [null "" {} [] "hello"]'';
          outcome = firstNonEmpty [null "" {} [] "hello"];
        };
        returnsNullWhenAllEmpty = mkTest {
          desired = null;
          command = ''firstNonEmpty [null "" {} []]'';
          outcome = firstNonEmpty [null "" {} []];
        };
        returnsFirstOfMany = mkTest {
          desired = "first";
          command = ''firstNonEmpty ["first" "second"]'';
          outcome = firstNonEmpty ["first" "second"];
        };
        zeroCountsAsNonEmpty = mkTest {
          desired = 0;
          command = "firstNonEmpty [null 0 1]";
          outcome = firstNonEmpty [null 0 1];
        };
        falseCountsAsNonEmpty = mkTest {
          desired = false;
          command = "firstNonEmpty [null false true]";
          outcome = firstNonEmpty [null false true];
        };
      };

      mapOrDefault = {
        appliesFnWhenNonEmpty = mkTest {
          desired = 6;
          command = "mapOrDefault { fn = x: x + 1; value = 5; default = 0; }";
          outcome = mapOrDefault {
            fn = x: x + 1;
            value = 5;
            default = 0;
          };
        };
        returnsDefaultForNull = mkTest {
          desired = 0;
          command = "mapOrDefault { fn = x: x + 1; value = null; default = 0; }";
          outcome = mapOrDefault {
            fn = x: x + 1;
            value = null;
            default = 0;
          };
        };
        returnsDefaultForEmptyString = mkTest {
          desired = "?";
          command = ''mapOrDefault { fn = s: s + "!"; value = ""; default = "?"; }'';
          outcome = mapOrDefault {
            fn = s: s + "!";
            value = "";
            default = "?";
          };
        };
        appliesFnToString = mkTest {
          desired = "hello!";
          command = ''mapOrDefault { fn = s: s + "!"; value = "hello"; default = "?"; }'';
          outcome = mapOrDefault {
            fn = s: s + "!";
            value = "hello";
            default = "?";
          };
        };
      };

      mapOrNull = {
        appliesFnWhenNonNull = mkTest {
          desired = "hello!";
          command = ''mapOrNull { fn = s: s + "!"; value = "hello"; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            value = "hello";
            default = "?";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "?";
          command = ''mapOrNull { fn = s: s + "!"; value = null; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            value = null;
            default = "?";
          };
        };
        transformsEmptyString = mkTest {
          desired = "!";
          command = ''mapOrNull { fn = s: s + "!"; value = ""; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            value = "";
            default = "?";
          };
        };
        transformsEmptyList = mkTest {
          desired = 0;
          command = "mapOrNull { fn = builtins.length; value = []; default = -1; }";
          outcome = mapOrNull {
            fn = builtins.length;
            value = [];
            default = -1;
          };
        };
      };
    };
  }
