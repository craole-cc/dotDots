/**
Core emptiness checking and value defaulting utilities.

This module provides fundamental predicates and transformations for handling
empty, null, or missing values in Nix expressions. These utilities enable
clean fallback patterns without verbose conditional logic.

# Key Concepts:
- "Empty" means: null, "", "  ", [], or {}
- Numbers (including 0), booleans (including false), functions, and paths are NEVER considered empty
- All functions are designed to work seamlessly with Nix's lazy evaluation

# Common Patterns:
```nix
# Simple defaulting
config = orDefault userConfig defaultConfig;

# Null-only check (preserve empty strings/lists)
value = orNull maybeNull fallback;

# Multi-level fallback
result = firstNonEmpty [customValue envValue configValue default];

# Conditional transformation
output = mapOrDefault processData input fallback;
```
*/
{lib, ...}: let
  # inherit (builtins) isNull;
  inherit (lib.lists) isList findFirst;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) isString trim stringLength;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  Determines emptiness based on type-specific rules. This is the foundation
  for all defaulting operations in this module.

  # Emptiness Rules
  - `null`: always empty
  - Strings: empty (`""`) or whitespace-only (`"  "`)
  - Lists: empty (`[]`)
  - Attribute sets: empty (`{}`)
  - Numbers: never empty (0 is a valid value)
  - Booleans: never empty (false is a valid value)
  - Functions: never empty
  - Paths: never empty
  - Other types: never empty

  # Type
  ```
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null           # => true
  isEmpty ""             # => true
  isEmpty "  "           # => true (whitespace-only)
  isEmpty []             # => true
  isEmpty {}             # => true
  isEmpty 0              # => false (zero is valid)
  isEmpty false          # => false (false is valid)
  isEmpty "hello"        # => false
  isEmpty [1 2 3]        # => false
  isEmpty { a = 1; }     # => false
  ```

  # Notes
  - Non-recursive: does not check nested structure contents
  - Whitespace trimming uses `lib.strings.trim`
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
  Check if a value is not empty.

  Convenience negation of `isEmpty`. Useful as a predicate in filters,
  conditionals, and other boolean contexts.

  # Type
  ```
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"     # => true
  isNotEmpty [1 2 3]     # => true
  isNotEmpty { a = 1; }  # => true
  isNotEmpty 0           # => true
  isNotEmpty false       # => true
  isNotEmpty null        # => false
  isNotEmpty ""          # => false
  isNotEmpty []          # => false
  isNotEmpty {}          # => false

  # Use in filters
  validConfigs = filter isNotEmpty allConfigs;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Return value or default if value is empty/null.

  The primary defaulting function. Evaluates `value` and returns `default`
  if `value` is empty according to `isEmpty` rules.

  # Type
  ```
  orDefault :: a -> a -> a
  ```

  # Arguments
  - `value`: The value to check for emptiness
  - `default`: The fallback value to return if `value` is empty

  # Returns
  `value` if non-empty, otherwise `default`

  # Examples
  ```nix
  orDefault "hello" "fallback"       # => "hello"
  orDefault null "fallback"          # => "fallback"
  orDefault "" "fallback"            # => "fallback"
  orDefault [] [1 2 3]               # => [1 2 3]
  orDefault {} { a = 1; }            # => { a = 1; }
  orDefault 0 42                     # => 0 (zero is not empty)
  orDefault false true               # => false (false is not empty)
  ```
  */
  orDefault = value: default:
    if isEmpty value
    then default
    else value;

  /**
  Return value or default if value is null (strict null check only).

  Unlike `orDefault`, this performs ONLY a null check, not an emptiness check.
  Use when you need to distinguish between `null` and empty values like `""` or `[]`.

  # Type
  ```
  orNull :: a -> a -> a
  ```

  # Arguments
  - `value`: The value to check for null
  - `default`: The fallback value to return if `value` is null

  # Returns
  `value` if not null (even if empty), otherwise `default`

  # Examples
  ```nix
  orNull "hello" "fallback"          # => "hello"
  orNull null "fallback"             # => "fallback"
  orNull "" "fallback"               # => "" (empty string is not null)
  orNull [] "fallback"               # => [] (empty list is not null)
  orNull {} "fallback"               # => {} (empty attrset is not null)
  orNull 0 42                        # => 0
  orNull false true                  # => false
  ```
  */
  orNull = value: default:
    if isNull value
    then default
    else value;

  /**
  Chain multiple values, returning first non-empty one.

  Evaluates a list of potential values in order and returns the first
  non-empty value encountered. Useful for multi-level fallback logic.

  # Type
  ```
  firstNonEmpty :: [a] -> a | null
  ```

  # Arguments
  - `values`: List of values to evaluate in order

  # Returns
  The first non-empty value in the list, or null if all are empty or list is empty

  # Examples
  ```nix
  firstNonEmpty ["" null "hello" "world"]    # => "hello"
  firstNonEmpty [null "" {} []]              # => null (all empty)
  firstNonEmpty [null "" "a" "b"]            # => "a"

  # Real-world: try multiple config sources
  finalValue = firstNonEmpty [
    (env.CUSTOM_VALUE or null)
    (config.userValue or null)
    (config.systemDefault or null)
    "built-in-default"
  ];
  ```
  */
  firstNonEmpty = values:
    findFirst isNotEmpty null values;

  /**
  Apply a function to value if non-empty, otherwise return default.

  Conditional function application with a fallback. Only applies the transform
  if the input is non-empty, otherwise returns the default unchanged.

  # Type
  ```
  mapOrDefault :: (a -> b) -> a -> b -> b
  ```

  # Arguments
  - `fn`: Transform function to apply to non-empty values
  - `value`: Input value to check and potentially transform
  - `default`: Fallback value if input is empty

  # Returns
  `fn value` if `value` is non-empty, otherwise `default`

  # Examples
  ```nix
  mapOrDefault (x: x + 1) 5 0           # => 6
  mapOrDefault (x: x + 1) null 0        # => 0
  mapOrDefault (s: s + "!") "hi" "?"    # => "hi!"
  mapOrDefault (s: s + "!") "" "?"      # => "?"

  # Real-world: process config if provided
  processedData = mapOrDefault
    (cfg: processConfig cfg)
    (userConfig or null)
    defaultProcessedConfig;
  ```
  */
  mapOrDefault = fn: value: default:
    if isEmpty value
    then default
    else fn value;

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
  exports // {_rootAliases = exports;}
