{
  _,
  __moduleRef,
  ...
}: let
  inherit (_.content.emptiness) isEmpty;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.runners) runTests;
  inherit (_.debug.tracing) tryEval;
  inherit (_.lists.access) findFirst length;

  exports = rec {
    internal = {
      inherit
        orDefault
        orNull
        orError
        firstNonEmpty
        mapOrDefault
        mapOrNull
        mapOrError
        ;
    };
    external = internal;
  };

  debug = mkModuleDebug __moduleRef;

  /**
  Return `value` if non-empty, otherwise `default`.

  The primary defaulting function - covers null, `""`, `[]`, and `{}`.

  # Type
  ```nix
  orDefault :: { content :: a, default :: a } -> a
  ```

  # Examples
  ```nix
  orDefault { content = "hello"; default = "fallback"; }  # => "hello"
  orDefault { content = null;    default = "fallback"; }  # => "fallback"
  orDefault { content = "";      default = "fallback"; }  # => "fallback"
  orDefault { content = 0;       default = 42;         }  # => 0
  orDefault { content = false;   default = true;       }  # => false
  ```
  */
  orDefault = {
    content,
    default,
  }:
    if isEmpty content
    then default
    else content;

  /**
  Return `content` if not null, otherwise `default`.

  Stricter than `orDefault` - only guards against null. Use when you need to
  preserve empty strings, lists, or attrsets.

  # Type
  ```nix
  orNull :: { content :: a, default :: a } -> a
  ```
  */
  orNull = {
    content,
    default,
  }:
    if content == null
    then default
    else content;

  /**
  Throw if `content` is empty, otherwise return it.
  */
  orError = {
    content,
    message,
  }:
    if isEmpty content
    then
      throw (
        debug.mkError {
          function = "orError";
          inherit message;
        }
      )
    else content;

  /** Return the first non-empty value from a list, or null. */
  firstNonEmpty = findFirst (v: !isEmpty v) null;

  /** Apply `fn` to `value` if non-empty, otherwise return `default`. */
  mapOrDefault = {
    fn,
    content,
    default,
  }:
    if isEmpty content
    then default
    else fn content;

  /** Apply `fn` to `value` if non-null, otherwise return `default`. */
  mapOrNull = {
    fn,
    content,
    default,
  }:
    if content == null
    then default
    else fn content;

  /** Apply `fn` to `content` if non-empty, otherwise throw. */
  mapOrError = {
    fn,
    content,
    message,
  }:
    if isEmpty content
    then
      throw (
        debug.mkError {
          function = "mapOrError";
          inherit message;
        }
      )
    else fn content;
in
  exports.internal
  // {
    __rootAliases = exports.external;

    __tests = runTests {
      orDefault = {
        returnsValueWhenNonEmpty = mkTest {
          desired = "hello";
          command = ''orDefault { content = "hello"; default = "fallback"; }'';
          outcome = orDefault {
            content = "hello";
            default = "fallback";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "fallback";
          command = ''orDefault { content = null; default = "fallback"; }'';
          outcome = orDefault {
            content = null;
            default = "fallback";
          };
        };
        returnsDefaultForEmptyString = mkTest {
          desired = "fallback";
          command = ''orDefault { content = ""; default = "fallback"; }'';
          outcome = orDefault {
            content = "";
            default = "fallback";
          };
        };
        returnsDefaultForWhitespace = mkTest {
          desired = "fallback";
          command = ''orDefault { content = "  "; default = "fallback"; }'';
          outcome = orDefault {
            content = "  ";
            default = "fallback";
          };
        };
        returnsDefaultForEmptyList = mkTest {
          desired = "fallback";
          command = ''orDefault { content = []; default = "fallback"; }'';
          outcome = orDefault {
            content = [];
            default = "fallback";
          };
        };
        returnsDefaultForEmptyAttrs = mkTest {
          desired = "fallback";
          command = ''orDefault { content = {}; default = "fallback"; }'';
          outcome = orDefault {
            content = {};
            default = "fallback";
          };
        };
        zeroIsNotEmpty = mkTest {
          desired = 0;
          command = "orDefault { content = 0; default = 42; }";
          outcome = orDefault {
            content = 0;
            default = 42;
          };
        };
        falseIsNotEmpty = mkTest {
          desired = false;
          command = "orDefault { content = false; default = true; }";
          outcome = orDefault {
            content = false;
            default = true;
          };
        };
      };

      orNull = {
        returnsValueWhenNonNull = mkTest {
          desired = "hello";
          command = ''orNull { content = "hello"; default = "fallback"; }'';
          outcome = orNull {
            content = "hello";
            default = "fallback";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "fallback";
          command = ''orNull { content = null; default = "fallback"; }'';
          outcome = orNull {
            content = null;
            default = "fallback";
          };
        };
        preservesEmptyString = mkTest {
          desired = "";
          command = ''orNull { content = ""; default = "fallback"; }'';
          outcome = orNull {
            content = "";
            default = "fallback";
          };
        };
        preservesEmptyList = mkTest {
          desired = [];
          command = "orNull { content = []; default = [1]; }";
          outcome = orNull {
            content = [];
            default = [1];
          };
        };
        preservesEmptyAttrs = mkTest {
          desired = {};
          command = "orNull { content = {}; default = { a = 1; }; }";
          outcome = orNull {
            content = {};
            default = {
              a = 1;
            };
          };
        };
      };

      orError = {
        returnsValueWhenNonEmpty = mkTest {
          desired = "hello";
          command = ''orError { content = "hello"; message = "required"; }'';
          outcome = orError {
            content = "hello";
            message = "required";
          };
        };
        throwsForNull = mkTest {
          desired = {
            success = false;
            value = false;
          };
          command = ''orError { content = null; message = "required"; }'';
          outcome = tryEval (orError {
            content = null;
            message = "required";
          });
        };
        throwsForEmptyString = mkTest {
          desired = {
            success = false;
            value = false;
          };
          command = ''orError { content = ""; message = "required"; }'';
          outcome = tryEval (orError {
            content = "";
            message = "required";
          });
        };
        throwsForEmptyList = mkTest {
          desired = {
            success = false;
            value = false;
          };
          command = ''orError { content = []; message = "required"; }'';
          outcome = tryEval (orError {
            content = [];
            message = "required";
          });
        };
        zeroDoesNotThrow = mkTest {
          desired = 0;
          command = ''orError { content = 0; message = "required"; }'';
          outcome = orError {
            content = 0;
            message = "required";
          };
        };
        falseDoesNotThrow = mkTest {
          desired = false;
          command = ''orError { content = false; message = "required"; }'';
          outcome = orError {
            content = false;
            message = "required";
          };
        };
      };

      firstNonEmpty = {
        returnsFirstNonEmpty = mkTest {
          desired = "hello";
          command = ''firstNonEmpty ["" null "hello" "world"]'';
          outcome = firstNonEmpty [
            ""
            null
            "hello"
            "world"
          ];
        };
        skipsNullAndEmpty = mkTest {
          desired = "hello";
          command = ''firstNonEmpty [null "" {} [] "hello"]'';
          outcome = firstNonEmpty [
            null
            ""
            {}
            []
            "hello"
          ];
        };
        returnsNullWhenAllEmpty = mkTest {
          desired = null;
          command = ''firstNonEmpty [null "" {} []]'';
          outcome = firstNonEmpty [
            null
            ""
            {}
            []
          ];
        };
        returnsFirstOfMany = mkTest {
          desired = "first";
          command = ''firstNonEmpty ["first" "second"]'';
          outcome = firstNonEmpty [
            "first"
            "second"
          ];
        };
        zeroCountsAsNonEmpty = mkTest {
          desired = 0;
          command = "firstNonEmpty [null 0 1]";
          outcome = firstNonEmpty [
            null
            0
            1
          ];
        };
        falseCountsAsNonEmpty = mkTest {
          desired = false;
          command = "firstNonEmpty [null false true]";
          outcome = firstNonEmpty [
            null
            false
            true
          ];
        };
      };

      mapOrDefault = {
        appliesFnWhenNonEmpty = mkTest {
          desired = 6;
          command = "mapOrDefault { fn = x: x + 1; content = 5; default = 0; }";
          outcome = mapOrDefault {
            fn = x: x + 1;
            content = 5;
            default = 0;
          };
        };
        returnsDefaultForNull = mkTest {
          desired = 0;
          command = "mapOrDefault { fn = x: x + 1; content = null; default = 0; }";
          outcome = mapOrDefault {
            fn = x: x + 1;
            content = null;
            default = 0;
          };
        };
        returnsDefaultForEmptyString = mkTest {
          desired = "?";
          command = ''mapOrDefault { fn = s: s + "!"; content = ""; default = "?"; }'';
          outcome = mapOrDefault {
            fn = s: s + "!";
            content = "";
            default = "?";
          };
        };
        appliesFnToString = mkTest {
          desired = "hello!";
          command = ''mapOrDefault { fn = s: s + "!"; content = "hello"; default = "?"; }'';
          outcome = mapOrDefault {
            fn = s: s + "!";
            content = "hello";
            default = "?";
          };
        };
      };

      mapOrNull = {
        appliesFnWhenNonNull = mkTest {
          desired = "hello!";
          command = ''mapOrNull { fn = s: s + "!"; content = "hello"; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            content = "hello";
            default = "?";
          };
        };
        returnsDefaultForNull = mkTest {
          desired = "?";
          command = ''mapOrNull { fn = s: s + "!"; content = null; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            content = null;
            default = "?";
          };
        };
        transformsEmptyString = mkTest {
          desired = "!";
          command = ''mapOrNull { fn = s: s + "!"; content = ""; default = "?"; }'';
          outcome = mapOrNull {
            fn = s: s + "!";
            content = "";
            default = "?";
          };
        };
        transformsEmptyList = mkTest {
          desired = 0;
          command = "mapOrNull { fn = length; content = []; default = -1; }";
          outcome = mapOrNull {
            fn = length;
            content = [];
            default = -1;
          };
        };
      };

      mapOrError = {
        appliesFnWhenNonEmpty = mkTest {
          desired = 6;
          command = ''mapOrError { fn = x: x + 1; content = 5; message = "required"; }'';
          outcome = mapOrError {
            fn = x: x + 1;
            content = 5;
            message = "required";
          };
        };
        throwsForNull = mkTest {
          desired = {
            success = false;
            value = false;
          };
          command = ''mapOrError { fn = x: x + 1; content = null; message = "required"; }'';
          outcome = tryEval (mapOrError {
            fn = x: x + 1;
            content = null;
            message = "required";
          });
        };
        throwsForEmptyString = mkTest {
          desired = {
            success = false;
            value = false;
          };
          command = ''mapOrError { fn = s: s + "!"; content = ""; message = "required"; }'';
          outcome = tryEval (mapOrError {
            fn = s: s + "!";
            content = "";
            message = "required";
          });
        };
        appliesFnToNonEmptyList = mkTest {
          desired = 3;
          command = ''mapOrError { fn = length; content = [1 2 3]; message = "required"; }'';
          outcome = mapOrError {
            fn = length;
            content = [
              1
              2
              3
            ];
            message = "required";
          };
        };
      };
    };
  }
