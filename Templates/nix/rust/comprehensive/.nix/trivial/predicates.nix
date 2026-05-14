{lib}: let
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) isString;
  inherit (lib.lists) any elem isList;
  inherit (lib.trivial) isBool;

  /**
  Determine whether a value is empty.

  This function checks if a value is empty by testing multiple conditions:
  - An empty string
  - null value
  - An empty attribute set
  - An empty list

  # Inputs

  `x` (any type)
  : The value to check for emptiness.

  # Type

  ```
  isEmpty :: a -> bool
  ```

  # Return

  `true` if the value is empty, `false` otherwise.

  # Examples

  ```nix
  isEmpty ""        # Returns: true
  isEmpty null      # Returns: true
  isEmpty {}        # Returns: true
  isEmpty []        # Returns: true
  isEmpty "hello"   # Returns: false
  isEmpty { a = 1; } # Returns: false
  isEmpty [ 1 ]     # Returns: false
  ```
  */
  isEmpty = x:
    if x == null
    then true
    else if isAttrs x
    then x == {}
    else if isList x
    then x == []
    else if isString x
    then x == ""
    else false;
  # isEmpty = x:
  #   if isFunction x
  #   then false
  #   else if isPath x
  #   then false
  #   else (x == null || x == "" || x == [] || x == {});

  /**
  Determine whether a value is not empty.

  This is the logical negation of `lib.trivial.isEmpty`.

  # Inputs

  `x` (any type)
  : The value to check.

  # Type

  ```
  isNotEmpty :: a -> bool
  ```

  # Return

  `true` if the value is not empty, `false` otherwise.
  */
  isNotEmpty = x: !isEmpty x;

  hasAny = needles: haystack: any (x: elem x haystack) needles;

  # isDisabled = value:
  #   value
  #   == null
  #   || value == false
  #   || value == 0
  #   || value == {}
  #   || value == []
  #   || value == "";
  isDisabled = value: value == null || (isBool value && !value) || value == 0 || value == {} || value == [] || value == "";
  isEnabled = value: !isDisabled value;
in {
  inherit
    hasAny
    isEmpty
    isNotEmpty
    isDisabled
    isEnabled
    ;
}
