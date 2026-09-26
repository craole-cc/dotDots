{lix, ...}: let
  inherit (lix.attrsets) isAttrs;
  inherit (lix.lists) isList;
  inherit (lix.strings) isString stringLength trim;

  /**
  Whether a value is "empty": `null`, an empty/whitespace-only string, an
  empty list, or an empty attrset. Any other value (including `0`,
  `false`) is not considered empty.

  # Inputs

  `value`
  : The value to check. Any type.

  # Type

  ```
  isEmpty :: a -> Bool
  ```

  # Example

  ```nix
  isEmpty null       # => true
  isEmpty "   "      # => true
  isEmpty []         # => true
  isEmpty {}         # => true
  isEmpty "hi"       # => false
  isEmpty 0          # => false
  ```
  */
  isEmpty = value:
    if (value == null)
    then true
    else if isString value
    then ((value == "") || ((stringLength (trim value)) == 0))
    else if isList value
    then value == []
    else if isAttrs value
    then value == {}
    else false;

  /**
  Negation of `isEmpty`.

  # Inputs

  `value`
  : The value to check. Any type.

  # Type

  ```
  isNotEmpty :: a -> Bool
  ```

  # Example

  ```nix
  isNotEmpty "hi"  # => true
  isNotEmpty []    # => false
  ```
  */
  isNotEmpty = value: !isEmpty value;
in {inherit isEmpty isNotEmpty;}
