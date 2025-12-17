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
  inherit (builtins) isNull;
  inherit (lib.lists) isList;
  inherit (lib.attrsets) isAttrs attrNames;
  inherit (lib.strings) trim stringLength isString;

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
  - For deeply nested checks, see `isEmptySafe` in advanced modules
  - Whitespace trimming uses `lib.strings.trim`
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

  # Use Cases
  - Configuration value fallbacks
  - Optional parameter handling
  - Graceful degradation in module options
  - Default value provision in derivations
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

  # Use Cases
  - Distinguishing unset vs explicitly set to empty
  - API responses where `null` means "not found" but `""` means "empty string"
  - Optional fields where empty values have different semantics than null
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
  firstNonEmpty :: [a] -> a
  ```

  # Arguments
  - `values`: List of values to evaluate in order

  # Returns
  The first non-empty value in the list, or the last value if all are empty

  # Examples
  ```nix
  firstNonEmpty ["" null "hello" "world"]    # => "hello"
  firstNonEmpty [null "" {} []]              # => [] (last value, all empty)
  firstNonEmpty [null "" "a" "b"]            # => "a"
  firstNonEmpty [(config.custom or null)
                 (config.default or null)
                 "hardcoded"]                # => first non-empty config

  # Real-world: try multiple config sources
  finalValue = firstNonEmpty [
    (env.CUSTOM_VALUE or null)
    (config.userValue or null)
    (config.systemDefault or null)
    "built-in-default"
  ];
  ```

  # Use Cases
  - Configuration hierarchies (user → system → default)
  - Environment variable fallback chains
  - Multi-source data resolution
  - Optional dependency selection

  # Notes
  - Evaluates lazily: stops at first non-empty value
  - Returns last value if all are empty (not null)
  - Empty list input returns `null`
  */
  firstNonEmpty = values:
    if values == []
    then null
    else if isEmpty (builtins.head values)
    then firstNonEmpty (builtins.tail values)
    else builtins.head values;

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
  mapOrDefault (x: x * 2) [] [99]       # => [99]

  # Real-world: process config if provided
  processedData = mapOrDefault
    (cfg: processConfig cfg)
    (userConfig or null)
    defaultProcessedConfig;
  ```

  # Use Cases
  - Conditional data transformation pipelines
  - Optional preprocessing steps
  - Safe operations on potentially empty inputs
  - Combining validation with transformation

  # Notes
  - Function is not called if value is empty (lazy evaluation)
  - Useful for expensive transformations you want to skip on empty inputs
  */
  mapOrDefault = fn: value: default:
    if isEmpty value
    then default
    else fn value;

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
