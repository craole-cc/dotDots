{
  _,
  lib,
  ...
}: let
  inherit (_.lists.membership) isInList;
  inherit (lib.lists) toList any;

  /**
  Check if any element from input is in the allowed list.

  # Type
  ```nix
  isAnyInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  isAnyInList ["foo" "bar"] ["bar" "baz"] false  # => true
  isAnyInList ["foo"] ["bar" "baz"] false        # => false
  isAnyInList "foo" ["foo" "bar"] false          # => true
  ```
  */
  isAnyInList = input: allowedList: ignoreCase: let
    elements = toList input;
    checkElement = e: isInList e allowedList ignoreCase;
  in
    any checkElement elements;

  /**
  Check if all elements from input are in the allowed list.

  # Type
  ```nix
  areAllInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  areAllInList ["foo" "bar"] ["foo" "bar" "baz"] false  # => true
  areAllInList ["foo" "qux"] ["foo" "bar"] false        # => false
  areAllInList "foo" ["foo" "bar"] false                # => true
  ```
  */
  areAllInList = input: allowedList: ignoreCase:
    isInList input allowedList ignoreCase;

  /**
  Check if none of the elements from input are in the allowed list.

  # Type
  ```nix
  areNoneInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  areNoneInList ["qux"] ["foo" "bar"] false       # => true
  areNoneInList ["foo" "qux"] ["foo" "bar"] false # => false
  areNoneInList "baz" ["foo" "bar"] false         # => true
  ```
  */
  areNoneInList = input: allowedList: ignoreCase:
    !(isAnyInList input allowedList ignoreCase);

  /**
  Check if exactly one element from input is in the allowed list.

  # Type
  ```nix
  isExactlyOneInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  isExactlyOneInList ["foo" "qux"] ["foo" "bar"] false  # => true
  isExactlyOneInList ["foo" "bar"] ["foo" "bar"] false  # => false
  isExactlyOneInList ["qux" "zap"] ["foo" "bar"] false  # => false
  ```
  */
  isExactlyOneInList = input: allowedList: ignoreCase: let
    elements = toList input;
    matches = map (e: isInList e allowedList ignoreCase) elements;
    count =
      lib.foldl' (acc: v:
        if v
        then acc + 1
        else acc)
      0
      matches;
  in
    count == 1;

  /**
  Check if at least N elements from input are in the allowed list.

  # Type
  ```nix
  isAtLeastNInList :: Int -> a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - n: Minimum number of matches required
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  isAtLeastNInList 2 ["foo" "bar" "qux"] ["foo" "bar"] false  # => true
  isAtLeastNInList 3 ["foo" "bar" "qux"] ["foo" "bar"] false  # => false
  isAtLeastNInList 1 ["foo"] ["foo" "bar"] false              # => true
  ```
  */
  isAtLeastNInList = n: input: allowedList: ignoreCase: let
    elements = toList input;
    matches = map (e: isInList e allowedList ignoreCase) elements;
    count =
      lib.foldl' (acc: v:
        if v
        then acc + 1
        else acc)
      0
      matches;
  in
    count >= n;
in {
  inherit
    isAnyInList
    areAllInList
    areNoneInList
    isExactlyOneInList
    isAtLeastNInList
    ;
}
