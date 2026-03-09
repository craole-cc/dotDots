# values/_.nix
#
# Predicates and transformations for handling empty, null, or missing values.
#
# "Empty" means: null, "", "  ", [], or {}
# Numbers (including 0), booleans, functions, and paths are NEVER empty.
#
# Access via:  _.values.isEmpty, _.values.orDefault, _.values.firstNonEmpty, etc.
{lib, ...}: let
  inherit (lib.lists) isList findFirst;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) isString trim stringLength;
  isNull = builtins.isNull;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  # Emptiness Rules
  - `null`:                  always empty
  - Strings `""` or `"  "`: empty (whitespace-only counts)
  - Lists `[]`:              empty
  - Attrsets `{}`:           empty
  - Numbers, bools, paths, functions: **never** empty

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
  isEmpty { a = 1; }  # => false
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
  isNotEmpty "hello"     # => true
  isNotEmpty 0           # => true
  isNotEmpty false       # => true
  isNotEmpty null        # => false
  isNotEmpty ""          # => false
  isNotEmpty []          # => false

  # Use in filters
  validConfigs = filter isNotEmpty allConfigs;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Return `value` if non-empty, otherwise return `default`.

  # Type
  ```nix
  orDefault :: a -> a -> a
  ```

  # Examples
  ```nix
  orDefault "hello" "fallback"    # => "hello"
  orDefault null "fallback"       # => "fallback"
  orDefault "" "fallback"         # => "fallback"
  orDefault 0 42                  # => 0  (zero is not empty)
  orDefault false true            # => false (false is not empty)
  ```
  */
  orDefault = value: default:
    if isEmpty value
    then default
    else value;

  /**
  Return `value` if not null, otherwise return `default`.

  Stricter than `orDefault` — only guards against null, not empty strings/lists.
  Use when you need to distinguish `null` from `""` or `[]`.

  # Type
  ```nix
  orNull :: a -> a -> a
  ```

  # Examples
  ```nix
  orNull null "fallback"    # => "fallback"
  orNull "" "fallback"      # => ""   (empty string preserved)
  orNull [] "fallback"      # => []   (empty list preserved)
  orNull 0 42               # => 0
  ```
  */
  orNull = value: default:
    if isNull value
    then default
    else value;

  /**
  Return the first non-empty value from a list, or null if all are empty.

  # Type
  ```nix
  firstNonEmpty :: [a] -> a | null
  ```

  # Examples
  ```nix
  firstNonEmpty ["" null "hello" "world"]    # => "hello"
  firstNonEmpty [null "" {} []]              # => null

  finalValue = firstNonEmpty [
    (env.CUSTOM_VALUE or null)
    (config.userValue or null)
    "built-in-default"
  ];
  ```
  */
  firstNonEmpty = values:
    findFirst isNotEmpty null values;

  /**
  Apply `fn` to `value` if non-empty, otherwise return `default`.

  # Type
  ```nix
  mapOrDefault :: (a -> b) -> a -> b -> b
  ```

  # Examples
  ```nix
  mapOrDefault (x: x + 1) 5 0           # => 6
  mapOrDefault (x: x + 1) null 0        # => 0
  mapOrDefault (s: s + "!") "" "?"      # => "?"
  ```
  */
  mapOrDefault = fn: value: default:
    if isEmpty value
    then default
    else fn value;

  /**
  Apply `fn` to `value` if not null, otherwise return `default`.

  Like `mapOrDefault` but with null-only guard — preserves empty strings/lists.

  # Type
  ```nix
  mapOrNull :: (a -> b) -> a -> b -> b
  ```

  # Examples
  ```nix
  mapOrNull (s: s + "!") null "?"    # => "?"
  mapOrNull (s: s + "!") "" "?"      # => "!"  (empty string still transformed)
  ```
  */
  mapOrNull = fn: value: default:
    if isNull value
    then default
    else fn value;

  exports = {
    inherit
      firstNonEmpty
      isEmpty
      isNotEmpty
      mapOrDefault
      mapOrNull
      orDefault
      orNull
      ;
  };
in
  exports // {_rootAliases = exports;}
