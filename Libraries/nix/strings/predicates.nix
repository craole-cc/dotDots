{
  lib,
  _,
  ...
}: let
  inherit (_.strings.generators) toList;
  inherit (_.trivial.emptiness) isEmpty isNotEmpty;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) all any;
  inherit (lib.strings) hasInfix hasPrefix hasSuffix;

  # Internal: build a predicate that checks if any pattern matches any input value.
  _mkAnyPredicate = checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    any (p: any (v: checker p v) vs) ps;

  # Internal: build a predicate that requires ALL inputs to match at least one pattern.
  _mkAllPredicate = checker: patterns: input: let
    ps = toList patterns;
    vs = toList input;
  in
    all (v: any (p: checker p v) ps) vs;

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
    (mapAttrs (_: _mkAnyPredicate) {
      contains = hasInfix;
      startsWith = hasPrefix;
      endsWith = hasSuffix;
    })
    contains
    startsWith
    endsWith
    ;

  inherit
    (mapAttrs (_: _mkAllPredicate) {
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

  _tests = runTests {
    contains = {
      singlePattern = mkTest {
        desired = true;
        outcome = contains "foo" "foobar";
      };
      listPattern = mkTest {
        desired = true;
        outcome = contains ["foo" "bar"] "foobar";
      };
      listInput = mkTest {
        desired = true;
        outcome = contains "foo" ["baz" "foobar"];
      };
      noMatch = mkTest {
        desired = false;
        outcome = contains ["foo" "bar"] ["baz"];
      };
    };
    startsWith = {
      matches = mkTest {
        desired = true;
        outcome = startsWith "foo" "foobar";
      };
      noMatch = mkTest {
        desired = false;
        outcome = startsWith "bar" "foobar";
      };
    };
    endsWith = {
      matches = mkTest {
        desired = true;
        outcome = endsWith "bar" "foobar";
      };
      noMatch = mkTest {
        desired = false;
        outcome = endsWith "foo" "foobar";
      };
    };
    containsAll = {
      allMatch = mkTest {
        desired = true;
        outcome = containsAll "foo" ["foobar" "fooX"];
      };
      notAllMatch = mkTest {
        desired = false;
        outcome = containsAll "foo" ["foobar" "baz"];
      };
    };
  };
}
