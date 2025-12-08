{lib, ...}: let
  inherit (lib.lists) toList all elem;
  inherit (lib.strings) toLower;

  _checkMembership = input: allowedList: ignoreCase: let
    elements = toList input;
    normalizedList =
      if ignoreCase
      then map toLower allowedList
      else allowedList;
    checkElement =
      if ignoreCase
      then (e: elem (toLower e) normalizedList)
      else (e: elem e normalizedList);
  in
    all checkElement elements;

  /**
  Check if input element(s) are in the allowed list.

  # Type
  ```nix
  isInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  isInList "foo" ["foo" "bar"] false          # => true
  isInList ["foo" "bar"] ["foo" "bar"] false  # => true
  isInList "FOO" ["foo"] true                 # => true
  isInList "baz" ["foo" "bar"] false          # => false
  ```
  */
  isInList = _checkMembership;

  /**
  Check if input element(s) are NOT in the allowed list.

  # Type
  ```nix
  notInList :: a | [a] -> [a] -> Bool -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values
  - ignoreCase: Whether to ignore case when comparing strings

  # Examples
  ```nix
  notInList "baz" ["foo" "bar"] false          # => true
  notInList "foo" ["foo" "bar"] false          # => false
  notInList "FOO" ["foo"] true                 # => false
  ```
  */
  notInList = input: allowedList: ignoreCase:
    !(isInList input allowedList ignoreCase);

  /**
  Check if input element(s) are in the list (case-insensitive).

  # Type
  ```nix
  isInListCaseInsensitive :: a | [a] -> [a] -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values

  # Examples
  ```nix
  isInListCaseInsensitive "FOO" ["foo" "bar"]  # => true
  isInListCaseInsensitive "Foo" ["foo" "bar"]  # => true
  ```
  */
  isInListCaseInsensitive = input: allowedList:
    isInList input allowedList true;

  /**
  Check if input element(s) are NOT in the list (case-insensitive).

  # Type
  ```nix
  notInListCaseInsensitive :: a | [a] -> [a] -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values

  # Examples
  ```nix
  notInListCaseInsensitive "BAZ" ["foo" "bar"]  # => true
  notInListCaseInsensitive "FOO" ["foo" "bar"]  # => false
  ```
  */
  notInListCaseInsensitive = input: allowedList:
    notInList input allowedList true;

  /**
  Check if input element(s) are in the list (case-sensitive, convenience wrapper).

  # Type
  ```nix
  inList :: a | [a] -> [a] -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values

  # Examples
  ```nix
  inList "foo" ["foo" "bar"]  # => true
  inList "FOO" ["foo" "bar"]  # => false
  ```
  */
  inList = input: allowedList:
    isInList input allowedList false;

  /**
  Check if input element(s) are NOT in the list (case-sensitive, convenience wrapper).

  # Type
  ```nix
  notIn :: a | [a] -> [a] -> Bool
  ```

  # Arguments
  - input: Single element or list of elements to check
  - allowedList: List of allowed values

  # Examples
  ```nix
  notIn "baz" ["foo" "bar"]  # => true
  notIn "foo" ["foo" "bar"]  # => false
  ```
  */
  notIn = input: allowedList:
    notInList input allowedList false;
in {
  inherit
    isInList
    notInList
    isInListCaseInsensitive
    notInListCaseInsensitive
    inList
    notIn
    ;
}
