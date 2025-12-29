{
  lib,
  _,
  ...
}: let
  inherit
    (lib.lists)
    all
    any
    filter
    elem
    head
    tail
    sort
    length
    toList
    foldl'
    ;
  inherit (lib.attrsets) attrValues isAttrs;
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
  has = isIn;

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

  /**
  Find the most frequent item in a list with advanced tie-breaking options.

  # Type
  ```nix
  mostFrequent :: [a] -> {
    tiebreaker :: a -> a -> a,       # Function to break ties
    compareItems :: (a -> a -> Int)? # Custom comparison for tie sorting (like compare)
  }? -> a | null
  ```
  # Options
  - tiebreaker: Function that takes two tied items and returns the preferred one
  - compareItems: Optional comparison function that returns -1, 0, or 1.
    If provided, uses sort with this comparator and takes first item.
    Overrides tiebreaker if both are provided.

  # Examples
  ```nix
  #> Use alphabetical sorting for ties
  mostFrequent ["a" "b" "b" "a"] {
    compareItems = a: b:
      if a < b then -1
      else if a > b then 1
      else 0;
  }  # => "a"

  #> Custom tie logic (prefer shorter strings)
  mostFrequent ["abc" "ab" "abc" "ab"] {
    tiebreaker = a: b:
      if stringLength a < stringLength b
      then a else b;
  }  # => "ab"
  ```
  */
  mostFrequent = list: options: let
    opts =
      if isAttrs options
      then options
      else {};

    # Handle empty list
    result =
      if list == []
      then null
      else let
        # Count frequencies
        frequencies =
          foldl'
          (acc: item: let
            key = toString item;
            count = acc.${key}.count or 0;
            storedItem = acc.${key}.item or item;
          in
            acc
            // {
              ${key} = {
                item = storedItem;
                count = count + 1;
              };
            })
          {}
          list;

        itemsWithCounts = attrValues frequencies;

        # Find maximum frequency
        maxCount =
          foldl'
          (max: entry:
            if entry.count > max
            then entry.count
            else max)
          0
          itemsWithCounts;

        # Get all items with max frequency
        tiedItems = map (entry: entry.item) (
          filter (entry: entry.count == maxCount) itemsWithCounts
        );

        # Break the tie
        resolvedItem =
          if opts ? compareItems
          then
            # Use comparator and take first after sorting
            head (sort opts.compareItems tiedItems)
          else if opts ? tiebreaker
          then
            # Use tiebreaker function
            foldl'
            (current: next: opts.tiebreaker current next)
            (head tiedItems)
            (tail tiedItems)
          else
            # Default: first item in tiedItems list
            head tiedItems;
      in
        resolvedItem;
  in
    result;
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
    mostFrequent
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
    inherit (_.trivial.tests) mkTest runTests;
  in
    runTests {
      checkMembership = {
        singleValueFound = mkTest true (checkMembership {
          value = "foo";
          check = ["foo" "bar"];
        });
        singleValueNotFound = mkTest false (checkMembership {
          value = "baz";
          check = ["foo" "bar"];
        });
        listWithOneMatch = mkTest true (checkMembership {
          value = ["foo" "qux"];
          check = ["foo" "bar"];
        });
        listWithNoMatches = mkTest false (checkMembership {
          value = ["qux" "quux"];
          check = ["foo" "bar"];
        });
        listWithAllMatches = mkTest true (checkMembership {
          value = ["foo" "bar"];
          check = ["foo" "bar" "baz"];
        });
        caseInsensitiveByDefault = mkTest true (checkMembership {
          value = "FOO";
          check = ["foo" "bar"];
        });
        caseSensitiveWithExact = mkTest false (checkMembership {
          value = "FOO";
          check = ["foo" "bar"];
          exact = true;
        });
        emptyValueList = mkTest false (checkMembership {
          value = [];
          check = ["foo" "bar"];
        });
        singleCheckValue = mkTest true (checkMembership {
          value = ["foo" "bar"];
          check = "foo";
        });
      };

      countMatches = {
        noMatches = mkTest 0 (countMatches {
          value = ["qux" "quux"];
          check = ["foo" "bar"];
        });
        oneMatch = mkTest 1 (countMatches {
          value = ["foo" "qux"];
          check = ["foo" "bar"];
        });
        allMatch = mkTest 2 (countMatches {
          value = ["foo" "bar"];
          check = ["foo" "bar" "baz"];
        });
        singleValueMatch = mkTest 1 (countMatches {
          value = "foo";
          check = ["foo" "bar"];
        });
        singleValueNoMatch = mkTest 0 (countMatches {
          value = "qux";
          check = ["foo" "bar"];
        });
        caseInsensitive = mkTest 2 (countMatches {
          value = ["FOO" "Bar"];
          check = ["foo" "bar"];
        });
        caseSensitive = mkTest 0 (countMatches {
          value = ["FOO" "Bar"];
          check = ["foo" "bar"];
          exact = true;
        });
        duplicateValues = mkTest 2 (countMatches {
          value = ["foo" "foo"];
          check = ["foo" "bar"];
        });
      };

      isIn = {
        found = mkTest true (isIn "foo" ["foo" "bar"]);
        notFound = mkTest false (isIn "qux" ["foo" "bar"]);
        caseInsensitive = mkTest true (isIn "FOO" ["foo" "bar"]);
        listWithPartialMatch = mkTest true (isIn ["foo" "qux"] ["foo" "bar"]);
        checkAgainstSingleValue = mkTest true (isIn "foo" "foo");
      };

      isInExact = {
        caseSensitiveMatch = mkTest true (isInExact "foo" ["foo" "bar"]);
        caseSensitiveNoMatch = mkTest false (isInExact "FOO" ["foo" "bar"]);
        listWithCaseMismatch = mkTest true (isInExact ["FOO" "bar"] ["foo" "bar"]);
      };

      hasAll = {
        allElementsFound = mkTest true (hasAll ["foo" "bar"] ["foo" "bar" "baz"]);
        notAllElementsFound = mkTest false (hasAll ["foo" "qux"] ["foo" "bar"]);
        singleElementFound = mkTest true (hasAll "foo" ["foo" "bar"]);
        singleElementNotFound = mkTest false (hasAll "qux" ["foo" "bar"]);
        emptyList = mkTest true (hasAll [] ["foo" "bar"]);
        caseInsensitive = mkTest true (hasAll ["FOO" "BAR"] ["foo" "bar"]);
        checkAgainstSingleValue = mkTest true (hasAll ["foo"] "foo");
      };

      hasAllExact = {
        allMatchWithCorrectCase = mkTest true (hasAllExact ["foo" "bar"] ["foo" "bar" "baz"]);
        caseMismatch = mkTest false (hasAllExact ["FOO" "bar"] ["foo" "bar"]);
        partialCaseMismatch = mkTest false (hasAllExact ["foo" "Bar"] ["foo" "bar"]);
      };

      hasAtLeast = {
        exactlyTheCount = mkTest true (hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 2);
        moreThanTheCount = mkTest true (hasAtLeast ["foo" "bar"] ["foo" "bar" "baz"] 1);
        lessThanTheCount = mkTest false (hasAtLeast ["foo" "qux"] ["foo" "bar"] 2);
        zeroCount = mkTest true (hasAtLeast ["foo"] ["foo" "bar"] 0);
        noMatchesButZeroCount = mkTest true (hasAtLeast ["qux"] ["foo" "bar"] 0);
        caseInsensitive = mkTest true (hasAtLeast ["FOO" "BAR"] ["foo" "bar"] 2);
        checkWithSingleValue = mkTest true (hasAtLeast "foo" "foo" 1);
      };

      hasAtLeastExact = {
        exactCaseMatch = mkTest true (hasAtLeastExact ["foo" "bar"] ["foo" "bar"] 2);
        caseMismatch = mkTest false (hasAtLeastExact ["FOO" "bar"] ["foo" "bar"] 2);
      };

      hasAtMost = {
        exactlyTheCount = mkTest true (hasAtMost ["foo" "bar"] ["foo" "baz"] 1);
        lessThanTheCount = mkTest true (hasAtMost ["foo"] ["foo" "bar"] 2);
        moreThanTheCount = mkTest false (hasAtMost ["foo" "bar"] ["foo" "bar" "baz"] 1);
        noMatchesReturnsFalse = mkTest false (hasAtMost ["qux" "quux"] ["foo" "bar"] 5);
        caseInsensitive = mkTest true (hasAtMost ["FOO"] ["foo" "bar"] 1);
      };

      hasAtMostExact = {
        caseSensitiveMatch = mkTest true (hasAtMostExact ["foo"] ["foo" "bar"] 1);
        caseSensitiveNoMatch = mkTest false (hasAtMostExact ["FOO"] ["foo" "bar"] 1);
      };
    };
}
