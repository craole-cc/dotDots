{lib, ...}: let
  inherit (builtins) isNull;
  inherit (lib.lists) isList;
  inherit (lib.attrsets) isAttrs attrNames;
  inherit (lib.strings) trim stringLength isString;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  A value is empty if it's:
  - null
  - Empty or whitespace-only string
  - Empty list
  - Empty attribute set

  Numbers, booleans, functions, and paths are NEVER empty (0, false are valid values).

  # Type
  isEmpty :: a -> Bool

  # Examples
  isEmpty null           # => true
  isEmpty ""             # => true
  isEmpty "  "           # => true
  isEmpty []             # => true
  isEmpty {}             # => true
  isEmpty 0              # => false
  isEmpty false          # => false
  isEmpty "hello"        # => false
  */
  isEmpty = value:
    if isNull value
    then true
    else if isString value
    then value == "" || stringLength (trim value) == 0
    else if isList value
    then value == []
    else if isAttrs value
    then attrNames value == []
    else false;

  /**
  Return value or default if value is empty/null.

  This is the core generic defaulting function. Use this directly
  or use the specialized type-safe wrappers below.

  # Type
  orDefault :: a -> a -> a

  # Examples
  orDefault "hello" "fallback"  # => "hello"
  orDefault null "fallback"     # => "fallback"
  orDefault "" "fallback"       # => "fallback"
  orDefault 0 42                # => 0 (numbers never empty)
  orDefault false true          # => false (bools never empty)
  */
  orDefault = value: default:
    if isEmpty value
    then default
    else value;

  /**
  Return value or default if value is null (strict null check only).

  Unlike orDefault, this ONLY checks for null, not emptiness.
  Use when you want to distinguish between null and empty values.

  # Type
  orNull :: a -> a -> a

  # Examples
  orNull "hello" "fallback"  # => "hello"
  orNull null "fallback"     # => "fallback"
  orNull "" "fallback"       # => "" (empty string is not null)
  orNull [] "fallback"       # => [] (empty list is not null)
  */
  orNull = value: default:
    if isNull value
    then default
    else value;

  /**
  Chain multiple values, returning first non-empty one.

  Useful for trying multiple fallback sources in order.

  # Type
  firstNonEmpty :: [a] -> a

  # Examples
  firstNonEmpty ["" null "hello" "world"]  # => "hello"
  firstNonEmpty [null "" {} []]            # => last value (all empty)
  firstNonEmpty [null "" "a" "b"]          # => "a"
  */
  firstNonEmpty = values:
    if values == []
    then null
    else if isEmpty (builtins.head values)
    then firstNonEmpty (builtins.tail values)
    else builtins.head values;

  /**
  Apply a function to value if non-empty, otherwise return default.

  # Type
  mapOrDefault :: (a -> b) -> a -> b -> b

  # Examples
  mapOrDefault (x: x + 1) 5 0        # => 6
  mapOrDefault (x: x + 1) null 0     # => 0
  mapOrDefault (s: s + "!") "" "?"   # => "?"
  */
  mapOrDefault = fn: value: default:
    if isEmpty value
    then default
    else fn value;

  # Convenience wrappers
  isNotEmpty = value: !isEmpty value;

  exports = {
    inherit
      isEmpty
      isNotEmpty
      orDefault
      orNull
      firstNonEmpty
      mapOrDefault
      ;
  };
in
  exports
  // {
    _rootAliases = exports;
  }
