{
  lib,
  _,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (_) checkMembership countMatches isIn isInExact hasAll hasAllExact hasAtLeast hasAtLeastExact hasAtMost hasAtMostExact;

  # Test helper to create test cases
  mkTest = name: expected: actual: {
    inherit name expected;
    result = actual;
    passed = expected == actual;
  };

  # Run all tests and return results
  runTests = tests:
    mapAttrs (name: test: {
      inherit (test) expected result passed;
      error =
        if !test.passed
        then "Expected ${toString test.expected}, got ${toString test.result}"
        else null;
    })
    tests;
in {
  _tests = runTests {
    # ============================================================
    # checkMembership tests (ANY semantics)
    # ============================================================

    "checkMembership: single value found" =
      mkTest
      true
      (checkMembership {
        value = "foo";
        check = ["foo" "bar"];
      });

    "checkMembership: single value not found" =
      mkTest
      false
      (checkMembership {
        value = "baz";
        check = ["foo" "bar"];
      });

    "checkMembership: list with one match" =
      mkTest
      true
      (checkMembership {
        value = ["foo" "qux"];
        check = ["foo" "bar"];
      });

    "checkMembership: list with no matches" =
      mkTest
      false
      (checkMembership {
        value = ["qux" "quux"];
        check = ["foo" "bar"];
      });

    "checkMembership: list with all matches" =
      mkTest
      true
      (checkMembership {
        value = ["foo" "bar"];
        check = ["foo" "bar" "baz"];
      });

    "checkMembership: case-insensitive by default" =
      mkTest
      true
      (checkMembership {
        value = "FOO";
        check = ["foo" "bar"];
      });

    "checkMembership: case-sensitive with exact=true" =
      mkTest
      false
      (checkMembership {
        value = "FOO";
        check = ["foo" "bar"];
        exact = true;
      });

    "checkMembership: empty value list" =
      mkTest
      false
      (checkMembership {
        value = [];
        check = ["foo" "bar"];
      });

    # ============================================================
    # countMatches tests
    # ============================================================

    "countMatches: no matches" =
      mkTest
      0
      (countMatches {
        value = ["qux" "quux"];
        check = ["foo" "bar"];
      });

    "countMatches: one match" =
      mkTest
      1
      (countMatches {
        value = ["foo" "qux"];
        check = ["foo" "bar"];
      });

    "countMatches: all match" =
      mkTest
      2
      (countMatches {
        value = ["foo" "bar"];
        check = ["foo" "bar" "baz"];
      });

    "countMatches: single value match" =
      mkTest
      1
      (countMatches {
        value = "foo";
        check = ["foo" "bar"];
      });

    "countMatches: single value no match" =
      mkTest
      0
      (countMatches {
        value = "qux";
        check = ["foo" "bar"];
      });

    "countMatches: case-insensitive" =
      mkTest
      2
      (countMatches {
        value = ["FOO" "Bar"];
        check = ["foo" "bar"];
      });

    "countMatches: case-sensitive" =
      mkTest
      0
      (countMatches {
        value = ["FOO" "Bar"];
        check = ["foo" "bar"];
        exact = true;
      });

    # ============================================================
    # isIn / isInExact tests (convenience wrappers)
    # ============================================================

    "isIn: found" =
      mkTest
      true
      (isIn "foo" ["foo" "bar"]);

    "isIn: not found" =
      mkTest
      false
      (isIn "qux" ["foo" "bar"]);

    "isIn: case-insensitive" =
      mkTest
      true
      (isIn "FOO" ["foo" "bar"]);

    "isIn: list with partial match" =
      mkTest
      true
      (isIn ["foo" "qux"] ["foo" "bar"]);

    "isInExact: case-sensitive match" =
      mkTest
      true
      (isInExact "foo" ["foo" "bar"]);

    "isInExact: case-sensitive no match" =
      mkTest
      false
      (isInExact "FOO" ["foo" "bar"]);

    "isInExact: list with case mismatch" =
      mkTest
      true
      (isInExact ["FOO" "bar"] ["foo" "bar"]);

    # ============================================================
    # hasAll / hasAllExact tests (ALL semantics)
    # ============================================================

    "hasAll: all elements found" =
      mkTest
      true
      (hasAll ["foo" "bar"] ["foo" "bar" "baz"]);

    "hasAll: not all elements found" =
      mkTest
      false
      (hasAll ["foo" "qux"] ["foo" "bar"]);

    "hasAll: single element found" =
      mkTest
      true
      (hasAll "foo" ["foo" "bar"]);

    "hasAll: single element not found" =
      mkTest
      false
      (hasAll "qux" ["foo" "bar"]);

    "hasAll: empty list" =
      mkTest
      true
      (hasAll [] ["foo" "bar"]);

    "hasAll: case-insensitive" =
      mkTest
      true
      (hasAll ["FOO" "BAR"] ["foo" "bar"]);

    "hasAllExact: all match with correct case" =
      mkTest
      true
      (hasAllExact ["foo" "bar"] ["foo" "bar" "baz"]);

    "hasAllExact: case mismatch" =
      mkTest
      false
      (hasAllExact ["FOO" "bar"] ["foo" "bar"]);

    "hasAllExact: partial case mismatch" =
      mkTest
      false
      (hasAllExact ["foo" "Bar"] ["foo" "bar"]);

    # ============================================================
    # hasAtLeast tests
    # ============================================================

    "hasAtLeast: exactly the count" =
      mkTest
      true
      (hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 2);

    "hasAtLeast: more than the count" =
      mkTest
      true
      (hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 1);

    "hasAtLeast: less than the count" =
      mkTest
      false
      (hasAtLeast ["foo" "qux"] ["foo" "bar"] 2);

    "hasAtLeast: zero count" =
      mkTest
      true
      (hasAtLeast ["foo"] ["foo" "bar"] 0);

    "hasAtLeast: no matches but zero count" =
      mkTest
      true
      (hasAtLeast ["qux"] ["foo" "bar"] 0);

    "hasAtLeast: case-insensitive" =
      mkTest
      true
      (hasAtLeast ["FOO" "BAR"] ["foo" "bar"] 2);

    "hasAtLeastExact: exact case match" =
      mkTest
      true
      (hasAtLeastExact ["foo" "bar"] ["foo" "bar"] 2);

    "hasAtLeastExact: case mismatch" =
      mkTest
      false
      (hasAtLeastExact ["FOO" "bar"] ["foo" "bar"] 2);

    # ============================================================
    # hasAtMost tests
    # ============================================================

    "hasAtMost: exactly the count" =
      mkTest
      true
      (hasAtMost ["foo" "bar"] ["foo" "baz"] 1);

    "hasAtMost: less than the count" =
      mkTest
      true
      (hasAtMost ["foo"] ["foo" "bar"] 2);

    "hasAtMost: more than the count" =
      mkTest
      false
      (hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 1);

    "hasAtMost: no matches returns false" =
      mkTest
      false
      (hasAtMost ["qux" "quux"] ["foo" "bar"] 5);

    "hasAtMost: case-insensitive" =
      mkTest
      true
      (hasAtMost ["FOO"] ["foo" "bar"] 1);

    "hasAtMostExact: case-sensitive match" =
      mkTest
      true
      (hasAtMostExact ["foo"] ["foo" "bar"] 1);

    "hasAtMostExact: case-sensitive no match" =
      mkTest
      false
      (hasAtMostExact ["FOO"] ["foo" "bar"] 1);

    # ============================================================
    # Edge cases and combinations
    # ============================================================

    "checkMembership: single check value" =
      mkTest
      true
      (checkMembership {
        value = ["foo" "bar"];
        check = "foo";
      });

    "countMatches: duplicate values in list" =
      mkTest
      2
      (countMatches {
        value = ["foo" "foo"];
        check = ["foo" "bar"];
      });

    "hasAll: check against single value" =
      mkTest
      true
      (hasAll ["foo"] "foo");

    "isIn: check against single value" =
      mkTest
      true
      (isIn "foo" "foo");

    "hasAtLeast: check with single value" =
      mkTest
      true
      (hasAtLeast "foo" "foo" 1);
  };
}
