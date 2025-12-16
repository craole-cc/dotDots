{lib, ...}: let
  inherit (builtins) isNull;
  inherit (lib.lists) isList all;
  inherit (lib.attrsets) isAttrs attrNames attrValues;
  inherit (lib.strings) trim stringLength isString;
  inherit (lib.trivial) isBool isInt isFloat isFunction;
  inherit (lib.types) path;

  /**
  Check if a value is empty.

  Comprehensively checks various types for emptiness:
  - null: always empty
  - strings: empty or whitespace-only
  - lists: empty or all elements empty
  - attribute sets: empty or all values empty
  - numbers/bools/functions/paths: never empty

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null                    # => true
  isEmpty ""                      # => true
  isEmpty "   "                   # => true
  isEmpty []                      # => true
  isEmpty {}                      # => true
  isEmpty { a = ""; b = []; }     # => true
  isEmpty 0                       # => false
  isEmpty false                   # => false
  isEmpty "hello"                 # => false
  isEmpty [1 2 3]                 # => false
  ```
  */
  isEmpty = input:
    if isNull input
    then true
    else if isAttrs input
    then
      #? Empty attribute set or all values are empty
      let
        values = attrValues input;
        allEmpty = all isEmpty values;
      in
        (attrNames input == []) || allEmpty
    else if isList input
    then
      #? Empty list or all list elements are empty
      (input == []) || (all isEmpty input)
    else if isString input
    then
      #? Empty or whitespace-only string
      (input == "") || (stringLength (trim input) == 0)
    else if isInt input || isFloat input
    then
      #? Numbers are never empty (0 is a valid value)
      false
    else if isBool input
    then
      #? Booleans are never empty (false is a valid value)
      false
    else if isFunction input
    then
      #? Functions are never empty
      false
    else if path.check input
    then
      #? Paths are never empty
      false
    else
      #? For any other type, treat as not empty
      false;

  /**
  Check if a value is empty with depth limit protection.

  Enhanced version with configurable depth limit to prevent infinite recursion
  when checking deeply nested or circular structures.

  # Type
  ```nix
  isEmptySafe :: Int -> a -> Bool
  ```

  # Arguments
  - depthLimit: Maximum recursion depth before assuming not empty
  - input: Value to check for emptiness

  # Examples
  ```nix
  isEmptySafe 10 { a = { b = { c = ""; }; }; }  # => true
  isEmptySafe 2 { a = { b = { c = ""; }; }; }   # => false (hit depth limit)
  isEmptySafe 5 []                               # => true
  ```
  */
  isEmptySafe = depthLimit: input: let
    isEmptyRec = depth: val:
      if depth >= depthLimit
      then false #? Hit depth limit, assume not empty
      else if isNull val
      then true
      else if isAttrs val
      then let
        names = attrNames val;
      in
        if names == []
        then true
        else all (name: isEmptyRec (depth + 1) val.${name}) names
      else if isList val
      then val == [] || all (elem: isEmptyRec (depth + 1) elem) val
      else if isString val
      then val == "" || stringLength (trim val) == 0
      else false;
  in
    isEmptyRec 0 input;

  /**
  Check if a value is empty (functor version for advanced usage).

  Callable attribute set that handles all common Nix types.
  Can be used as a function or accessed for its implementation.

  # Type
  ```nix
  isEmptyWithTypes :: a -> Bool
  ```

  # Examples
  ```nix
  isEmptyWithTypes null           # => true
  isEmptyWithTypes {}             # => true
  isEmptyWithTypes ""             # => true
  isEmptyWithTypes { a = 0; }     # => false
  ```
  */
  isEmptyWithTypes = {
    __functor = _: input:
      if isNull input
      then true
      else if isAttrs input
      then let
        values = attrValues input;
        allEmpty = all isEmptyWithTypes values;
      in
        (attrNames input == []) || allEmpty
      else if isList input
      then input == [] || (all isEmptyWithTypes input)
      else if isString input
      then input == "" || (stringLength (trim input) == 0)
      else if isInt input || isFloat input
      then false
      else if isBool input
      then false
      else if input == {}
      then true
      else false;
  };

  /**
  Alias for isEmpty for semantic clarity.

  # Type
  ```nix
  isTrulyEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isTrulyEmpty null    # => true
  isTrulyEmpty ""      # => true
  isTrulyEmpty 0       # => false
  ```
  */
  isTrulyEmpty = input: isEmpty input;

  /**
  Check if a value is an empty string.

  Returns true only for empty or whitespace-only strings.

  # Type
  ```nix
  isEmptyString :: a -> Bool
  ```

  # Examples
  ```nix
  isEmptyString ""          # => true
  isEmptyString "   "       # => true
  isEmptyString "hello"     # => false
  isEmptyString []          # => false
  ```
  */
  isEmptyString = input: isString input && (input == "" || stringLength (trim input) == 0);

  /**
  Check if a value is an empty list.

  Returns true for empty lists or lists where all elements are empty.

  # Type
  ```nix
  isEmptyList :: a -> Bool
  ```

  # Examples
  ```nix
  isEmptyList []                  # => true
  isEmptyList ["" {} []]          # => true
  isEmptyList [1]                 # => false
  isEmptyList "not a list"        # => false
  ```
  */
  isEmptyList = input: isList input && (input == [] || all isEmpty input);

  /**
  Check if a value is an empty attribute set.

  Returns true for empty attribute sets or sets where all values are empty.

  # Type
  ```nix
  isEmptyAttrs :: a -> Bool
  ```

  # Examples
  ```nix
  isEmptyAttrs {}                    # => true
  isEmptyAttrs { a = ""; b = []; }   # => true
  isEmptyAttrs { a = 1; }            # => false
  isEmptyAttrs []                    # => false
  ```
  */
  isEmptyAttrs = input:
    isAttrs input
    && (
      (attrNames input == [])
      || (all (name: isEmpty input.${name}) (attrNames input))
    );

  /**
  Check if a value is not empty.

  Inverse of isEmpty.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"    # => true
  isNotEmpty [1 2 3]    # => true
  isNotEmpty 0          # => true
  isNotEmpty ""         # => false
  isNotEmpty null       # => false
  ```
  */
  isNotEmpty = input: !isEmpty input;
in {
  inherit
    isEmpty
    isEmptySafe
    isEmptyWithTypes
    isTrulyEmpty
    isEmptyString
    isEmptyList
    isEmptyAttrs
    isNotEmpty
    ;
}
