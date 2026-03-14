{
  __moduleRef,
  _,
  lib,
  ...
}: let
  inherit (_.debug.module) mkModuleDebug mkFn;
  inherit (_.debug.format) mkExample;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_.lists.generators) toList;
  inherit (_.lists.predicates) isList;
  inherit (_.types.predicates) typeOf;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.lists) any all;
  inherit (lib.strings) hasInfix hasPrefix hasSuffix toLower;

  debug = mkModuleDebug __moduleRef;

  mkAny = {
    name,
    fn,
    checker,
    patterns,
    input,
  }: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (debug.withDoc {
        function = mkFn {inherit name fn;};
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${name} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else any (p: any (v: checker p v) vs) ps;

  #? ALL inputs match at least one pattern.
  mkAll = {
    name,
    fn,
    checker,
    patterns,
    input,
  }: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (debug.withDoc {
        function = mkFn {inherit name fn;};
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${name} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else all (v: any (p: checker p v) ps) vs;

  mkChecker = caseSensitive: let
    normalize = s:
      if caseSensitive
      then s
      else toLower s;
  in
    pattern: str: hasInfix (normalize pattern) (normalize str);

  /**
  Check whether any pattern is contained in any input string.

  Accepts either a single string or a list of strings for both arguments.

  # Type
  ```nix
  contains :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  contains "foo" "foobar"           # => true
  contains ["foo" "bar"] "foobar"   # => true
  contains "foo" ["baz" "foobar"]   # => true
  contains ["foo" "bar"] ["baz"]    # => false
  ```
  */
  containsOld = patterns: input:
    mkAny {
      name = "containsOld";
      fn = containsOld;
      checker = hasInfix;
      inherit patterns input;
    };

  contains = patternsOrAttrs: inputOrPatterns: let
    # --- Detect call style --------------------------------------------------
    isAttrsetCall =
      isAttrs patternsOrAttrs
      && patternsOrAttrs ? patterns
      && patternsOrAttrs ? input;

    isOptsCall =
      isAttrs patternsOrAttrs
      && !(patternsOrAttrs ? patterns)
      && !(patternsOrAttrs ? input);

    # --- Resolve case sensitivity -------------------------------------------
    caseSensitive =
      if isAttrsetCall || isOptsCall
      then patternsOrAttrs.caseSensitive or false
      else false;

    checker = mkChecker caseSensitive;
  in
    if isAttrsetCall
    then
      # Style: contains { patterns = ...; input = ...; caseSensitive? = ...; }
      mkAny {
        name = "contains";
        fn = contains;
        inherit checker;
        patterns = patternsOrAttrs.patterns;
        input = patternsOrAttrs.input;
      }
    else if isOptsCall
    then
      # Style: contains { caseSensitive = true; } patterns input
      # inputOrPatterns holds `patterns` at this point; waiting for actual input
      (actualInput:
        mkAny {
          inherit checker;
          name = "contains";
          fn = contains;
          patterns = inputOrPatterns;
          input = actualInput;
        })
    else
      # Style: contains patterns input  (plain curried)
      mkAny {
        inherit checker;
        name = "contains";
        fn = contains;
        patterns = patternsOrAttrs;
        input = inputOrPatterns;
      };
  /**
  Check whether any input string starts with any of the given patterns.

  # Type
  ```nix
  startsWith :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  startsWith "foo" "foobar"           # => true
  startsWith ["foo" "bar"] "foobar"   # => true
  startsWith "foo" ["baz" "foobar"]   # => true
  startsWith ["foo" "bar"] ["baz"]    # => false
  ```
  */
  startsWith = patterns: input:
    mkAny {
      name = "startsWith";
      fn = startsWith;
      checker = hasPrefix;
      inherit patterns input;
    };

  /**
  Check whether any input string ends with any of the given patterns.

  # Type
  ```nix
  endsWith :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  endsWith "bar" "foobar"           # => true
  endsWith ["foo" "bar"] "foobar"   # => true
  endsWith "bar" ["baz" "foobar"]   # => true
  endsWith ["foo" "bar"] ["baz"]    # => false
  ```
  */
  endsWith = patterns: input:
    mkAny {
      name = "endsWith";
      fn = endsWith;
      checker = hasSuffix;
      inherit patterns input;
    };

  /**
  Check whether ALL input strings contain at least one of the given patterns.

  # Type
  ```nix
  containsAll :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  containsAll "foo" ["foobar" "fooX"]  # => true  (every input has "foo")
  containsAll "foo" ["foobar" "baz"]   # => false ("baz" doesn't contain "foo")
  ```
  */
  containsAll = patterns: input:
    mkAll {
      name = "containsAll";
      fn = containsAll;
      checker = hasInfix;
      inherit patterns input;
    };

  /**
  Check whether ALL input strings start with at least one of the given patterns.

  # Type
  ```nix
  startsWithAll :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  startsWithAll "foo" ["foobar" "fooX"]  # => true
  startsWithAll "foo" ["foobar" "barX"]  # => false
  ```
  */
  startsWithAll = patterns: input:
    mkAll {
      name = "startsWithAll";
      fn = startsWithAll;
      checker = hasPrefix;
      inherit patterns input;
    };

  /**
  Check whether ALL input strings end with at least one of the given patterns.

  # Type
  ```nix
  endsWithAll :: string | [string] -> string | [string] -> bool
  ```

  # Examples
  ```nix
  endsWithAll "bar" ["foobar" "bazbar"]  # => true
  endsWithAll "bar" ["foobar" "bazX"]    # => false
  ```
  */
  endsWithAll = patterns: input:
    mkAll {
      name = "endsWithAll";
      fn = endsWithAll;
      checker = hasSuffix;
      inherit patterns input;
    };

  /**
  Check whether a value is a string.

  # Type
  ```nix
  isString :: any -> bool
  ```

  # Examples
  ```nix
  isString "foo"  # => true
  isString 42     # => false
  isString null   # => false
  ```
  */
  isString = lib.strings.isString;

  /**
  Check whether a string is a binary digit — exactly `"0"` or `"1"`.

  # Type
  ```nix
  isBinary :: any -> bool
  ```

  # Examples
  ```nix
  isBinary "0"    # => true
  isBinary "1"    # => true
  isBinary "yes"  # => false
  isBinary 1      # => false
  ```
  */
  isBinary = s:
    typeOf s == "string" && (s == "0" || s == "1");

  /**
  Check whether a value can be converted to a string via `toString`.

  Includes strings, paths, numbers, booleans, and attrsets with a `__toString`
  or `outPath` attribute.

  # Type
  ```nix
  isStringConvertible :: any -> bool
  ```

  # Examples
  ```nix
  isStringConvertible "foo"       # => true
  isStringConvertible 42          # => true
  isStringConvertible /etc/hosts  # => true
  isStringConvertible { a = 1; }  # => false
  ```
  */
  isConvertible = lib.strings.isConvertibleWithToString;

  /**
  Check whether a value is string-like — a string or a value with `outPath`.

  Useful for accepting both strings and derivations/packages wherever a path
  or string is expected.

  # Type
  ```nix
  isLike :: any -> bool
  ```

  # Examples
  ```nix
  isLike "foo"                # => true
  isLike { outPath = "..."; } # => true
  isLike 42                   # => false
  ```
  */
  isLike = lib.strings.isStringLike;

  /**
  Check whether a string is a valid POSIX filename component.

  A valid POSIX name contains only alphanumerics, hyphens, underscores, and dots,
  and does not start with a hyphen.

  # Type
  ```nix
  isPOSIX :: string -> bool
  ```

  # Examples
  ```nix
  isPOSIX "foo-bar"   # => true
  isPOSIX "foo bar"   # => false (space not allowed)
  isPOSIX "-foo"      # => false (cannot start with hyphen)
  ```
  */
  isPOSIX = lib.strings.isValidPosixName;

  exports = {
    inherit
      contains
      containsAll
      endsWith
      endsWithAll
      isBinary
      isPOSIX
      isString
      startsWith
      startsWithAll
      isConvertible
      isLike
      ;
  };
in
  exports
  // {
    _rootAliases = {
      inherit isString;
      isStringLike = isLike;
      isBinaryString = isBinary;
      isStringConvertible = isConvertible;
      isPOSIXString = isPOSIX;
      stringContains = contains;
      stringContainsAll = containsAll;
      stringEndsWith = endsWith;
      stringEndsWithAll = endsWithAll;
      stringStartsWith = startsWith;
      stringStartsWithAll = startsWithAll;
    };

    _tests = runTests {
      contains = {
        singlePattern = mkTest {
          desired = true;
          command = ''contains "foo" "foobar"'';
          outcome = contains "foo" "foobar";
        };
        listPattern = mkTest {
          desired = true;
          command = ''contains ["foo" "bar"] "foobar"'';
          outcome = contains ["foo" "bar"] "foobar";
        };
        listInput = mkTest {
          desired = true;
          command = ''contains "foo" ["baz" "foobar"]'';
          outcome = contains "foo" ["baz" "foobar"];
        };
        noMatch = mkTest {
          desired = false;
          command = ''contains ["foo" "bar"] ["baz"]'';
          outcome = contains ["foo" "bar"] ["baz"];
        };
      };
      startsWith = {
        matches = mkTest {
          desired = true;
          command = ''startsWith "foo" "foobar"'';
          outcome = startsWith "foo" "foobar";
        };
        noMatch = mkTest {
          desired = false;
          command = ''startsWith "bar" "foobar"'';
          outcome = startsWith "bar" "foobar";
        };
        listInput = mkTest {
          desired = true;
          command = ''startsWith "foo" ["foobar" "fooX"]'';
          outcome = startsWith "foo" ["foobar" "fooX"];
        };
      };
      endsWith = {
        matches = mkTest {
          desired = true;
          command = ''endsWith "bar" "foobar"'';
          outcome = endsWith "bar" "foobar";
        };
        noMatch = mkTest {
          desired = false;
          command = ''endsWith "foo" "foobar"'';
          outcome = endsWith "foo" "foobar";
        };
        listInput = mkTest {
          desired = true;
          command = ''endsWith "bar" ["foobar" "bazbar"]'';
          outcome = endsWith "bar" ["foobar" "bazbar"];
        };
      };
      containsAll = {
        allMatch = mkTest {
          desired = true;
          command = ''containsAll "foo" ["foobar" "fooX"]'';
          outcome = containsAll "foo" ["foobar" "fooX"];
        };
        notAllMatch = mkTest {
          desired = false;
          command = ''containsAll "foo" ["foobar" "baz"]'';
          outcome = containsAll "foo" ["foobar" "baz"];
        };
      };
      startsWithAll = {
        allMatch = mkTest {
          desired = true;
          command = ''startsWithAll "foo" ["foobar" "fooX"]'';
          outcome = startsWithAll "foo" ["foobar" "fooX"];
        };
        notAllMatch = mkTest {
          desired = false;
          command = ''startsWithAll "foo" ["foobar" "barX"]'';
          outcome = startsWithAll "foo" ["foobar" "barX"];
        };
      };
      endsWithAll = {
        allMatch = mkTest {
          desired = true;
          command = ''endsWithAll "bar" ["foobar" "bazbar"]'';
          outcome = endsWithAll "bar" ["foobar" "bazbar"];
        };
        notAllMatch = mkTest {
          desired = false;
          command = ''endsWithAll "bar" ["foobar" "bazX"]'';
          outcome = endsWithAll "bar" ["foobar" "bazX"];
        };
      };

      isString = {
        detectsString = mkTest {
          desired = true;
          command = ''isString "foo"'';
          outcome = isString "foo";
        };
        detectsEmpty = mkTest {
          desired = true;
          command = ''isString ""'';
          outcome = isString "";
        };
        rejectsInt = mkTest {
          desired = false;
          command = "isString 42";
          outcome = isString 42;
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isString null";
          outcome = isString null;
        };
        rejectsBool = mkTest {
          desired = false;
          command = "isString true";
          outcome = isString true;
        };
        rejectsList = mkTest {
          desired = false;
          command = "isString []";
          outcome = isString [];
        };
      };

      isBinary = {
        detectsZero = mkTest {
          desired = true;
          command = ''isBinary "0"'';
          outcome = isBinary "0";
        };
        detectsOne = mkTest {
          desired = true;
          command = ''isBinary "1"'';
          outcome = isBinary "1";
        };
        rejectsOtherString = mkTest {
          desired = false;
          command = ''isBinary "yes"'';
          outcome = isBinary "yes";
        };
        rejectsInt = mkTest {
          desired = false;
          command = "isBinary 1";
          outcome = isBinary 1;
        };
        rejectsEmpty = mkTest {
          desired = false;
          command = ''isBinary ""'';
          outcome = isBinary "";
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isBinary null";
          outcome = isBinary null;
        };
      };

      isConvertible = {
        detectsString = mkTest {
          desired = true;
          command = ''isConvertible "foo"'';
          outcome = isConvertible "foo";
        };
        detectsInt = mkTest {
          desired = true;
          command = "isConvertible 42";
          outcome = isConvertible 42;
        };
        detectsBool = mkTest {
          desired = true;
          command = "isConvertible true";
          outcome = isConvertible true;
        };
        detectsToStringAttrs = mkTest {
          desired = true;
          command = ''isConvertible { __toString = _: "x"; }'';
          outcome = isConvertible {__toString = _: "x";};
        };
        detectsOutPath = mkTest {
          desired = true;
          command = ''isConvertible { outPath = "/nix/store/foo"; }'';
          outcome = isConvertible {outPath = "/nix/store/foo";};
        };
        rejectsPlainAttrs = mkTest {
          desired = false;
          command = ''isConvertible { a = 1; }'';
          outcome = isConvertible {a = 1;};
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isConvertible null";
          outcome = isConvertible null;
        };
      };

      isLike = {
        detectsString = mkTest {
          desired = true;
          command = ''isLike "foo"'';
          outcome = isLike "foo";
        };
        detectsOutPath = mkTest {
          desired = true;
          command = ''isLike { outPath = "/nix/store/foo"; }'';
          outcome = isLike {outPath = "/nix/store/foo";};
        };
        rejectsInt = mkTest {
          desired = false;
          command = "isLike 42";
          outcome = isLike 42;
        };
        rejectsPlainAttrs = mkTest {
          desired = false;
          command = ''isLike { a = 1; }'';
          outcome = isLike {a = 1;};
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isLike null";
          outcome = isLike null;
        };
      };

      isPOSIX = {
        detectsSimpleName = mkTest {
          desired = true;
          command = ''isPOSIX "foo"'';
          outcome = isPOSIX "foo";
        };
        detectsHyphenated = mkTest {
          desired = true;
          command = ''isPOSIX "foo-bar"'';
          outcome = isPOSIX "foo-bar";
        };
        detectsUnderscored = mkTest {
          desired = true;
          command = ''isPOSIX "foo_bar"'';
          outcome = isPOSIX "foo_bar";
        };
        detectsDotted = mkTest {
          desired = true;
          command = ''isPOSIX "foo.bar"'';
          outcome = isPOSIX "foo.bar";
        };
        rejectsSpace = mkTest {
          desired = false;
          command = ''isPOSIX "foo bar"'';
          outcome = isPOSIX "foo bar";
        };
        rejectsLeadingHyphen = mkTest {
          desired = false;
          command = ''isPOSIX "-foo"'';
          outcome = isPOSIX "-foo";
        };
        rejectsSlash = mkTest {
          desired = false;
          command = ''isPOSIX "foo/bar"'';
          outcome = isPOSIX "foo/bar";
        };
      };
    };
  }
