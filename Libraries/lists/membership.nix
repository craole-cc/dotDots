{lib, ...}: let
  inherit (lib.lists) toList all elem;
  inherit (lib.strings) toLower;

  /**
  Check if input element(s) are in the allowed list.

  # Type
  ```nix
  check :: a | [a] -> a | [a] -> Bool -> Bool
  ```

  # Arguments
  - item: Single element or list of elements to check
  - list: List of allowed values
  - exact: Whether to use exact (case-sensitive) matching when comparing strings (default: false)

  # Examples
  ```nix
  check { item = "foo"; list = "foo"; } # => true
  check { item = "foo"; list = "bar"; } # => false
  check { item = "foo"; list = ["foo" "bar"]; } # => true
  check { item = "FOO"; list = ["foo" "bar"]; exact = true; } # => false
  ```
  */
  check = {
    item,
    list,
    exact ? false,
  }: let
    elements = toList item;
    checkList = toList list;
    normalizedList =
      if exact
      then checkList
      else map toLower checkList;
    check =
      if exact
      then (e: elem e normalizedList)
      else (e: elem (toLower e) normalizedList);
  in
    all check elements;
in {
  inherit
    check
    # isInList
    # notInList
    # isInListCaseInsensitive
    # notInListCaseInsensitive
    # inList
    # notIn
    ;
}
