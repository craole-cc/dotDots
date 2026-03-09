# values/empty.nix
#
# Emptiness predicates.
#
# "Empty" means: null, "", "  ", [], {}
# Numbers (including 0), booleans, functions, and paths are NEVER empty.
{lib, ...}: let
  inherit (lib.lists) isList;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) isString trim stringLength;
  # isNull = builtins.isNull;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  # Emptiness Rules
  - `null`:             always empty
  - Strings:            empty when `""` or whitespace-only
  - Lists:              empty when `[]`
  - Attrsets:           empty when `{}`
  - Numbers, booleans, paths, functions: **never** empty

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null        # => true
  isEmpty ""          # => true
  isEmpty "  "        # => true
  isEmpty []          # => true
  isEmpty {}          # => true
  isEmpty 0           # => false
  isEmpty false       # => false
  isEmpty "hello"     # => false
  isEmpty [1 2 3]     # => false
  ```
  */
  isEmpty = value:
    if isNull value
    then true
    else if isString value
    then stringLength (trim value) == 0
    else if isList value
    then value == []
    else if isAttrs value
    then value == {}
    else false;

  /**
  Check if a value is not empty. Convenience negation of `isEmpty`.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"  # => true
  isNotEmpty 0        # => true
  isNotEmpty false    # => true
  isNotEmpty null     # => false
  isNotEmpty ""       # => false

  # Common use in filters
  validItems = filter isNotEmpty rawList;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  exports = {inherit isEmpty isNotEmpty;};
in
  exports // {_rootAliases = exports;}
