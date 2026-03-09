{
  __libraryPath,
  _,
  lib,
  ...
}: let
  _debug = mkModuleDebug __libraryPath;

  inherit (_.strings.generators) toList;
  inherit (_.trivial.emptiness) isEmpty isNotEmpty;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) all any isList;
  inherit (lib.strings) hasInfix hasPrefix hasSuffix isString;

  # Internal: build a predicate that checks if any pattern matches any input value.
  _mkAnyPredicate = function: checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (_debug.withDoc {
        inherit function;
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${function} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else any (p: any (v: checker p v) vs) ps;

  # Internal: build a predicate that requires ALL inputs to match at least one pattern.
  _mkAllPredicate = function: checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    if !(isString patterns || isList patterns)
    then
      throw (_debug.withDoc {
        inherit function;
        message = "patterns must be a string or list of strings";
        signature = "string | [string] -> string | [string] -> bool";
        input = patterns;
        example = mkExample {
          cmd = ''${function} "foo" ["bar" "baz"]'';
          res = "true";
        };
      })
    else all (v: any (p: checker p v) ps) vs;

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
  inherit
    (mapAttrs (name: checker: _mkAnyPredicate name checker) {
      contains = hasInfix;
      startsWith = hasPrefix;
      endsWith = hasSuffix;
    })
    contains
    startsWith
    endsWith
    ;

  inherit
    (mapAttrs (name: checker: _mkAllPredicate name checker) {
      containsAll = hasInfix;
      startsWithAll = hasPrefix;
      endsWithAll = hasSuffix;
    })
    containsAll
    startsWithAll
    endsWithAll
    ;
in {
  inherit
    contains
    containsAll
    endsWith
    endsWithAll
    isEmpty
    isNotEmpty
    startsWith
    startsWithAll
    ;

  _rootAliases = {
    stringContains = contains;
    stringContainsAll = containsAll;
    stringEndsWith = endsWith;
    stringEndsWithAll = endsWithAll;
    stringStartsWith = startsWith;
    stringStartsWithAll = startsWithAll;
    #? isEmpty/isNotEmpty intentionally omitted — owned by trivial.emptiness
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
  };
}
