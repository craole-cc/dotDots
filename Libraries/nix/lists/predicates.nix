{
  __libraryPath,
  _,
  lib,
  ...
}: let
  _debug = mkModuleDebug __libraryPath;

  inherit (_.strings.transform) toLower;
  inherit (_.strings.generators) toList;
  inherit (_.trivial.predicates) isList;
  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.lists) all any elem filter length;

  /**
  Generate a membership checking function for a normalized list.

  When exact = false, performs case-insensitive comparison by normalizing
  both the check list and tested elements to lowercase.

  # Type
  ```nix
  mkCheckList :: { check :: a | [a], exact :: Bool } -> (a -> Bool)
  ```

  # Examples
  ```nix
  isMember = mkCheckList { check = ["foo" "bar"]; };
  isMember "foo"  # => true
  isMember "FOO"  # => true (case-insensitive by default)
  isMember "baz"  # => false
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
    if !(isList checkList)
    then
      throw (_debug.withDoc {
        function = "mkCheckList";
        message = "check must be a value or list of values";
        signature = "{ check :: a | [a], exact :: Bool } -> (a -> Bool)";
        input = check;
        example = mkExample {
          cmd = ''mkCheckList { check = ["foo" "bar"]; }'';
          res = "(a -> Bool)";
        };
      })
    else if exact
    then (e: e != null && elem e normalizedList)
    else (e: e != null && elem (toLower e) normalizedList);

  /**
  Check if any input elements are members of the allowed list.

  Returns true if ANY element from `value` is found in `check`.

  # Type
  ```nix
  checkMembership :: { value :: a | [a], check :: a | [a], exact :: Bool } -> Bool
  ```

  # Examples
  ```nix
  checkMembership { value = "foo"; check = ["foo" "bar"]; }           # => true
  checkMembership { value = ["foo" "bar"]; check = ["foo" "baz"]; }   # => true
  checkMembership { value = "FOO"; check = ["foo"]; exact = false; }  # => true
  checkMembership { value = "FOO"; check = ["foo"]; exact = true; }   # => false
  ```
  */
  checkMembership = {
    value,
    check,
    exact ? false,
  }:
    any (mkCheckList {inherit check exact;}) (toList value);

  /**
  Count how many elements from `value` are found in `check`.

  # Type
  ```nix
  countMatches :: { value :: a | [a], check :: a | [a], exact :: Bool } -> Int
  ```

  # Examples
  ```nix
  countMatches { value = ["foo" "bar"]; check = ["foo" "baz"]; }  # => 1
  countMatches { value = ["foo" "bar"]; check = ["foo" "bar"]; }  # => 2
  countMatches { value = ["FOO" "Bar"]; check = ["foo" "bar"]; }  # => 2
  ```
  */
  countMatches = {
    value,
    check,
    exact ? false,
  }:
    length (filter (mkCheckList {inherit check exact;}) (toList value));

  /**
  Check if any value(s) exist in the check list (case-insensitive).

  # Examples
  ```nix
  isIn "foo" ["foo" "bar"]          # => true
  isIn "FOO" ["foo" "bar"]          # => true
  isIn ["foo" "qux"] ["foo" "bar"]  # => true (foo matches)
  ```
  */
  isIn = value: check:
    checkMembership {
      inherit value check;
      exact = false;
    };

  has = isIn;

  /**
  Check if any value(s) exist in the check list (case-sensitive).

  # Examples
  ```nix
  isInExact "foo" ["foo" "bar"]          # => true
  isInExact "FOO" ["foo" "bar"]          # => false
  isInExact ["FOO" "bar"] ["foo" "bar"]  # => true (bar matches)
  ```
  */
  isInExact = value: check:
    checkMembership {
      inherit value check;
      exact = true;
    };

  /**
  Check if at least `count` elements from `value` are in `check` (case-insensitive).

  # Examples
  ```nix
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
  hasAtMost ["foo" "bar"] ["foo" "baz"] 1        # => true  (1 match)
  hasAtMost ["foo" "bar"] ["foo" "bar"] 1        # => false (2 matches > 1)
  hasAtMost ["foo" "bar"] ["baz" "qux"] 5        # => false (0 matches)
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

  # Examples
  ```nix
  hasAll ["foo" "bar"] ["foo" "bar" "baz"]  # => true
  hasAll ["foo" "qux"] ["foo" "bar"]        # => false
  hasAll "foo" ["foo" "bar"]                # => true
  ```
  */
  hasAll = value: check:
    all (mkCheckList {
      inherit check;
      exact = false;
    }) (toList value);

  /**
  Check if all elements from `value` are in `check` (case-sensitive).

  # Examples
  ```nix
  hasAllExact ["foo" "bar"] ["foo" "bar" "baz"]  # => true
  hasAllExact ["foo" "Bar"] ["foo" "bar"]        # => false
  ```
  */
  hasAllExact = value: check:
    all (mkCheckList {
      inherit check;
      exact = true;
    }) (toList value);
in {
  inherit
    checkMembership
    countMatches
    has
    hasAll
    hasAllExact
    hasAtLeast
    hasAtLeastExact
    hasAtMost
    hasAtMostExact
    isIn
    isInExact
    isList
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

  _tests = runTests {
    checkMembership = {
      singleValueFound = mkTest {
        desired = true;
        command = ''checkMembership { value = "foo"; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = "foo";
          check = ["foo" "bar"];
        };
      };
      singleValueNotFound = mkTest {
        desired = false;
        command = ''checkMembership { value = "baz"; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = "baz";
          check = ["foo" "bar"];
        };
      };
      listWithOneMatch = mkTest {
        desired = true;
        command = ''checkMembership { value = ["foo" "qux"]; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = ["foo" "qux"];
          check = ["foo" "bar"];
        };
      };
      listWithNoMatches = mkTest {
        desired = false;
        command = ''checkMembership { value = ["qux" "quux"]; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = ["qux" "quux"];
          check = ["foo" "bar"];
        };
      };
      caseInsensitiveByDefault = mkTest {
        desired = true;
        command = ''checkMembership { value = "FOO"; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = "FOO";
          check = ["foo" "bar"];
        };
      };
      caseSensitiveWithExact = mkTest {
        desired = false;
        command = ''checkMembership { value = "FOO"; check = ["foo" "bar"]; exact = true; }'';
        outcome = checkMembership {
          value = "FOO";
          check = ["foo" "bar"];
          exact = true;
        };
      };
      emptyValueList = mkTest {
        desired = false;
        command = ''checkMembership { value = []; check = ["foo" "bar"]; }'';
        outcome = checkMembership {
          value = [];
          check = ["foo" "bar"];
        };
      };
      singleCheckValue = mkTest {
        desired = true;
        command = ''checkMembership { value = ["foo" "bar"]; check = "foo"; }'';
        outcome = checkMembership {
          value = ["foo" "bar"];
          check = "foo";
        };
      };
    };

    countMatches = {
      noMatches = mkTest {
        desired = 0;
        command = ''countMatches { value = ["qux" "quux"]; check = ["foo" "bar"]; }'';
        outcome = countMatches {
          value = ["qux" "quux"];
          check = ["foo" "bar"];
        };
      };
      oneMatch = mkTest {
        desired = 1;
        command = ''countMatches { value = ["foo" "qux"]; check = ["foo" "bar"]; }'';
        outcome = countMatches {
          value = ["foo" "qux"];
          check = ["foo" "bar"];
        };
      };
      allMatch = mkTest {
        desired = 2;
        command = ''countMatches { value = ["foo" "bar"]; check = ["foo" "bar" "baz"]; }'';
        outcome = countMatches {
          value = ["foo" "bar"];
          check = ["foo" "bar" "baz"];
        };
      };
      caseInsensitive = mkTest {
        desired = 2;
        command = ''countMatches { value = ["FOO" "Bar"]; check = ["foo" "bar"]; }'';
        outcome = countMatches {
          value = ["FOO" "Bar"];
          check = ["foo" "bar"];
        };
      };
      caseSensitive = mkTest {
        desired = 0;
        command = ''countMatches { value = ["FOO" "Bar"]; check = ["foo" "bar"]; exact = true; }'';
        outcome = countMatches {
          value = ["FOO" "Bar"];
          check = ["foo" "bar"];
          exact = true;
        };
      };
      duplicateValues = mkTest {
        desired = 2;
        command = ''countMatches { value = ["foo" "foo"]; check = ["foo" "bar"]; }'';
        outcome = countMatches {
          value = ["foo" "foo"];
          check = ["foo" "bar"];
        };
      };
    };

    isIn = {
      found = mkTest {
        desired = true;
        command = ''isIn "foo" ["foo" "bar"]'';
        outcome = isIn "foo" ["foo" "bar"];
      };
      notFound = mkTest {
        desired = false;
        command = ''isIn "qux" ["foo" "bar"]'';
        outcome = isIn "qux" ["foo" "bar"];
      };
      caseInsensitive = mkTest {
        desired = true;
        command = ''isIn "FOO" ["foo" "bar"]'';
        outcome = isIn "FOO" ["foo" "bar"];
      };
      listWithPartialMatch = mkTest {
        desired = true;
        command = ''isIn ["foo" "qux"] ["foo" "bar"]'';
        outcome = isIn ["foo" "qux"] ["foo" "bar"];
      };
      checkAgainstSingleValue = mkTest {
        desired = true;
        command = ''isIn "foo" "foo"'';
        outcome = isIn "foo" "foo";
      };
    };

    isInExact = {
      caseSensitiveMatch = mkTest {
        desired = true;
        command = ''isInExact "foo" ["foo" "bar"]'';
        outcome = isInExact "foo" ["foo" "bar"];
      };
      caseSensitiveNoMatch = mkTest {
        desired = false;
        command = ''isInExact "FOO" ["foo" "bar"]'';
        outcome = isInExact "FOO" ["foo" "bar"];
      };
      listWithCaseMismatch = mkTest {
        desired = true;
        command = ''isInExact ["FOO" "bar"] ["foo" "bar"]'';
        outcome = isInExact ["FOO" "bar"] ["foo" "bar"];
      };
    };

    hasAll = {
      allElementsFound = mkTest {
        desired = true;
        command = ''hasAll ["foo" "bar"] ["foo" "bar" "baz"]'';
        outcome = hasAll ["foo" "bar"] ["foo" "bar" "baz"];
      };
      notAllElementsFound = mkTest {
        desired = false;
        command = ''hasAll ["foo" "qux"] ["foo" "bar"]'';
        outcome = hasAll ["foo" "qux"] ["foo" "bar"];
      };
      caseInsensitive = mkTest {
        desired = true;
        command = ''hasAll ["FOO" "BAR"] ["foo" "bar"]'';
        outcome = hasAll ["FOO" "BAR"] ["foo" "bar"];
      };
      emptyList = mkTest {
        desired = true;
        command = ''hasAll [] ["foo" "bar"]'';
        outcome = hasAll [] ["foo" "bar"];
      };
    };

    hasAllExact = {
      allMatchWithCorrectCase = mkTest {
        desired = true;
        command = ''hasAllExact ["foo" "bar"] ["foo" "bar" "baz"]'';
        outcome = hasAllExact ["foo" "bar"] ["foo" "bar" "baz"];
      };
      caseMismatch = mkTest {
        desired = false;
        command = ''hasAllExact ["FOO" "bar"] ["foo" "bar"]'';
        outcome = hasAllExact ["FOO" "bar"] ["foo" "bar"];
      };
    };

    hasAtLeast = {
      exactlyTheCount = mkTest {
        desired = true;
        command = ''hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 2'';
        outcome = hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 2;
      };
      moreThanTheCount = mkTest {
        desired = true;
        command = ''hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 1'';
        outcome = hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 1;
      };
      lessThanTheCount = mkTest {
        desired = false;
        command = ''hasAtLeast ["foo" "qux"] ["foo" "bar"] 2'';
        outcome = hasAtLeast ["foo" "qux"] ["foo" "bar"] 2;
      };
      caseInsensitive = mkTest {
        desired = true;
        command = ''hasAtLeast ["FOO" "BAR"] ["foo" "bar"] 2'';
        outcome = hasAtLeast ["FOO" "BAR"] ["foo" "bar"] 2;
      };
    };

    hasAtLeastExact = {
      exactCaseMatch = mkTest {
        desired = true;
        command = ''hasAtLeastExact ["foo" "bar"] ["foo" "bar"] 2'';
        outcome = hasAtLeastExact ["foo" "bar"] ["foo" "bar"] 2;
      };
      caseMismatch = mkTest {
        desired = false;
        command = ''hasAtLeastExact ["FOO" "bar"] ["foo" "bar"] 2'';
        outcome = hasAtLeastExact ["FOO" "bar"] ["foo" "bar"] 2;
      };
    };

    hasAtMost = {
      exactlyTheCount = mkTest {
        desired = true;
        command = ''hasAtMost ["foo" "bar"] ["foo" "baz"] 1'';
        outcome = hasAtMost ["foo" "bar"] ["foo" "baz"] 1;
      };
      lessThanTheCount = mkTest {
        desired = true;
        command = ''hasAtMost ["foo"] ["foo" "bar"] 2'';
        outcome = hasAtMost ["foo"] ["foo" "bar"] 2;
      };
      moreThanTheCount = mkTest {
        desired = false;
        command = ''hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 1'';
        outcome = hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 1;
      };
      noMatchesReturnsFalse = mkTest {
        desired = false;
        command = ''hasAtMost ["qux" "quux"] ["foo" "bar"] 5'';
        outcome = hasAtMost ["qux" "quux"] ["foo" "bar"] 5;
      };
      caseInsensitive = mkTest {
        desired = true;
        command = ''hasAtMost ["FOO"] ["foo" "bar"] 1'';
        outcome = hasAtMost ["FOO"] ["foo" "bar"] 1;
      };
    };

    hasAtMostExact = {
      caseSensitiveMatch = mkTest {
        desired = true;
        command = ''hasAtMostExact ["foo"] ["foo" "bar"] 1'';
        outcome = hasAtMostExact ["foo"] ["foo" "bar"] 1;
      };
      caseSensitiveNoMatch = mkTest {
        desired = false;
        command = ''hasAtMostExact ["FOO"] ["foo" "bar"] 1'';
        outcome = hasAtMostExact ["FOO"] ["foo" "bar"] 1;
      };
    };
  };
}
