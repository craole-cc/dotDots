{lib, ...}: let
  inherit (lib.lists) all any filter elem length toList;
  inherit (lib.strings) toLower;

  /**
  Generate a membership checking function for a normalized list.

  Creates a predicate function that checks if an element exists in the provided list.
  When exact = false, performs case-insensitive string comparison by normalizing both
  the check list and tested elements to lowercase.

  # Type
  ```nix
  mkCheckList :: { check :: a | [a], exact :: Bool } -> (a -> Bool)
  ```

  # Arguments
  - check: Single element or list of allowed values to check against
  - exact: Whether to use exact (case-sensitive) matching for strings (default: false)

  # Returns
  A predicate function that takes an element and returns true if it's in the check list

  # Examples
  ```nix
  isMember = mkCheckList { check = ["foo" "bar"]; exact = false; };
  isMember "foo"  # => true
  isMember "FOO"  # => true (case-insensitive)
  isMember "baz"  # => false

  isMemberExact = mkCheckList { check = ["foo" "bar"]; exact = true; };
  isMemberExact "FOO"  # => false (case-sensitive)
  ```
  */
  mkCheckList = {
    check,
    exact ? false,
  }: let
    checkList = toList check;
    normalizedList =
      if exact
      then checkList
      else map toLower checkList;
  in
    if exact
    then (e: elem e normalizedList)
    else (e: elem (toLower e) normalizedList);

  /**
  Check if any input elements are members of the allowed list.

  Tests whether at least one element in `value` exists in the `check` list.
  Returns true if ANY element from `value` is found in `check`.

  # Type
  ```nix
  checkMembership :: { value :: a | [a], check :: a | [a], exact :: Bool } -> Bool
  ```

  # Arguments
  - value: Single element or list of elements to verify membership for
  - check: Single element or list of allowed values
  - exact: Whether to use exact (case-sensitive) matching for strings (default: false)

  # Returns
  true if any element in `value` is in `check`, false otherwise

  # Examples
  ```nix
  checkMembership { value = "foo"; check = ["foo" "bar"]; }
  # => true

  checkMembership { value = ["foo" "bar"]; check = ["foo" "baz"]; }
  # => true (foo is found)

  checkMembership { value = ["foo" "qux"]; check = ["bar" "baz"]; }
  # => false (neither found)

  checkMembership { value = "FOO"; check = ["foo"]; exact = false; }
  # => true (case-insensitive)

  checkMembership { value = "FOO"; check = ["foo"]; exact = true; }
  # => false (case-sensitive)
  ```
  */
  checkMembership = {
    value,
    check,
    exact ? false,
  }: let
    valueList = toList value;
    isMember = mkCheckList {inherit check exact;};
  in
    any isMember valueList;

  /**
  Count how many elements from `value` are found in `check`.

  Returns the number of elements from the first argument that exist in the second.
  Useful for quantifying partial matches between two lists.

  # Type
  ```nix
  countMatches :: { value :: a | [a], check :: a | [a], exact :: Bool } -> Int
  ```

  # Arguments
  - value: Single element or list of elements to count matches for
  - check: Single element or list of values to check against
  - exact: Whether to use exact (case-sensitive) matching for strings (default: false)

  # Returns
  The count of elements from `value` that are present in `check`

  # Examples
  ```nix
  countMatches { value = "foo"; check = ["foo" "bar"]; }
  # => 1

  countMatches { value = ["foo" "bar"]; check = ["foo" "baz"]; }
  # => 1 (only "foo" matches)

  countMatches { value = ["foo" "bar"]; check = ["foo" "bar"]; }
  # => 2 (both match)

  countMatches { value = ["foo" "bar" "baz"]; check = ["qux"]; }
  # => 0 (no matches)
  ```
  */
  countMatches = {
    value,
    check,
    exact ? false,
  }: let
    valueList = toList value;
    isMember = mkCheckList {inherit check exact;};
  in
    length (filter isMember valueList);

  # Membership predicates
  # These functions check if values exist in a list

  /**
  Check if any value(s) exist in the check list (case-insensitive).

  Convenient wrapper for checkMembership with exact = false.
  Returns true if at least one element from value is in check.

  # Examples
  ```nix
  isIn "foo" ["foo" "bar"]          # => true
  isIn "FOO" ["foo" "bar"]          # => true
  isIn ["foo" "bar"] ["foo" "baz"]  # => true (foo matches)
  isIn ["qux" "quux"] ["foo" "bar"] # => false (no matches)
  ```
  */
  isIn = value: check:
    checkMembership {
      inherit value check;
      exact = false;
    };

  /**
  Check if any value(s) exist in the check list (case-sensitive).

  Convenient wrapper for checkMembership with exact = true.
  Returns true if at least one element from value is in check.

  # Examples
  ```nix
  isInExact "foo" ["foo" "bar"]  # => true
  isInExact "FOO" ["foo" "bar"]  # => false
  isInExact ["FOO" "bar"] ["foo" "bar"]  # => true (bar matches)
  ```
  */
  isInExact = value: check:
    checkMembership {
      inherit value check;
      exact = true;
    };

  # Quantitative predicates
  # These functions check quantities of matches

  /**
  Check if at least `count` elements from `value` are in `check` (case-insensitive).

  # Examples
  ```nix
  hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 1  # => true
  hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 2  # => true
  hasAtLeast ["foo" "bar"] ["foo" "baz"] 2        # => false
  ```
  */
  hasAtLeast = value: check: count:
    countMatches {inherit value check;} >= count;

  /**
  Check if at least `count` elements from `value` are in `check` (case-sensitive).
  */
  hasAtLeastExact = value: check: count:
    countMatches {
      inherit value check;
      exact = true;
    }
    >= count;

  /**
  Check if at most `count` elements from `value` are in `check` (case-insensitive).

  Requires at least one match to return true.

  # Examples
  ```nix
  hasAtMost ["foo" "bar"] ["foo" "baz"] 1  # => true (1 match)
  hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 2  # => true (2 matches)
  hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 1  # => false (2 matches > 1)
  hasAtMost ["foo" "bar"] ["baz" "qux"] 5  # => false (0 matches)
  ```
  */
  hasAtMost = value: check: count: let
    matches = countMatches {inherit value check;};
  in
    matches >= 1 && matches <= count;

  /**
  Check if at most `count` elements from `value` are in `check` (case-sensitive).

  Requires at least one match to return true.
  */
  hasAtMostExact = value: check: count: let
    matches = countMatches {
      inherit value check;
      exact = true;
    };
  in
    matches >= 1 && matches <= count;

  /**
  Check if all elements from `value` are in `check` (case-insensitive).

  Unlike checkMembership (which checks for ANY match), this requires ALL
  elements to be present in the check list.

  # Examples
  ```nix
  hasAll ["foo" "bar"] ["foo" "bar" "baz"]  # => true (both found)
  hasAll ["foo" "qux"] ["foo" "bar"]        # => false (qux not found)
  hasAll "foo" ["foo" "bar"]                # => true (single element)
  ```
  */
  hasAll = value: check: let
    valueList = toList value;
    isMember = mkCheckList {
      inherit check;
      exact = false;
    };
  in
    all isMember valueList;

  /**
  Check if all elements from `value` are in `check` (case-sensitive).

  Unlike checkMembership (which checks for ANY match), this requires ALL
  elements to be present in the check list with exact case matching.

  # Examples
  ```nix
  hasAllExact ["foo" "bar"] ["foo" "bar" "baz"]  # => true
  hasAllExact ["foo" "Bar"] ["foo" "bar"]        # => false (Bar != bar)
  ```
  */
  hasAllExact = value: check: let
    valueList = toList value;
    isMember = mkCheckList {
      inherit check;
      exact = true;
    };
  in
    all isMember valueList;
in {
  inherit
    checkMembership
    countMatches
    hasAll
    hasAllExact
    hasAtLeast
    hasAtLeastExact
    hasAtMost
    hasAtMostExact
    isIn
    isInExact
    ;

  _rootAliases = {
    checkListMembership = checkMembership;
    countListMatches = countMatches;
    hasAllInList = hasAll;
    hasAllExactInList = hasAllExact;
    hasAtLeastInList = hasAtLeast;
    hasAtLeastExactInList = hasAtLeastExact;
    hasAtMostInList = hasAtMost;
    hasAtMostExactInList = hasAtMostExact;
    isInList = isIn;
    isInExactList = isInExact;
  };

  _tests = let
    inherit (lib.attrsets) mapAttrs;

    mkTest = name: expected: actual: {
      inherit name expected;
      result = actual;
      passed = expected == actual;
    };

    runTests = tests:
      mapAttrs (name: test: {
        inherit (test) expected result passed;
        error =
          if !test.passed
          then "Expected ${toString test.expected}, got ${toString test.result}"
          else null;
      })
      tests;
  in
    runTests {
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
