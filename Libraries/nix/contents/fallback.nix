# values/fallback.nix
#
# Fallback and defaulting functions for missing or empty values.
{
  _,
  lib,
  ...
}: let
  inherit (_.contents.empty) isEmpty;
  inherit (lib.lists) findFirst;

  /**
  Return `value` if non-empty, otherwise `default`.

  The primary defaulting function — covers null, `""`, `[]`, and `{}`.

  # Type
  ```nix
  orDefault :: { value :: a, default :: a } -> a
  ```

  # Examples
  ```nix
  orDefault { value = "hello"; default = "fallback"; }  # => "hello"
  orDefault { value = null;    default = "fallback"; }  # => "fallback"
  orDefault { value = "";      default = "fallback"; }  # => "fallback"
  orDefault { value = 0;       default = 42;         }  # => 0     (zero is not empty)
  orDefault { value = false;   default = true;       }  # => false (false is not empty)
  ```
  */
  orDefault = {
    value,
    default,
  }:
    if isEmpty value
    then default
    else value;

  /**
  Return `value` if not null, otherwise `default`.

  Stricter than `orDefault` — only guards against null. Use when you need to
  preserve empty strings, lists, or attrsets.

  # Type
  ```nix
  orNull :: { value :: a, default :: a } -> a
  ```

  # Examples
  ```nix
  orNull { value = null; default = "fallback"; }  # => "fallback"
  orNull { value = "";   default = "fallback"; }  # => ""  (empty string preserved)
  orNull { value = [];   default = "fallback"; }  # => []  (empty list preserved)
  ```
  */
  orNull = {
    value,
    default,
  }:
    if value == null
    then default
    else value;

  /**
  Return the first non-empty value from a list, or null if all are empty.

  Single-arg so stays curried — the list is the whole input.

  # Type
  ```nix
  firstNonEmpty :: [a] -> a | null
  ```

  # Examples
  ```nix
  firstNonEmpty ["" null "hello" "world"]  # => "hello"
  firstNonEmpty [null "" {} []]            # => null

  value = firstNonEmpty [
    (env.CUSTOM_VALUE or null)
    (config.userValue  or null)
    "built-in-default"
  ];
  ```
  */
  firstNonEmpty = findFirst (v: !isEmpty v) null;

  /**
  Apply `fn` to `value` if non-empty, otherwise return `default`.

  # Type
  ```nix
  mapOrDefault :: { fn :: (a -> b), value :: a, default :: b } -> b
  ```

  # Examples
  ```nix
  mapOrDefault { fn = x: x + 1;    value = 5;    default = 0;   }  # => 6
  mapOrDefault { fn = x: x + 1;    value = null; default = 0;   }  # => 0
  mapOrDefault { fn = s: s + "!";  value = "";   default = "?"; }  # => "?"
  ```
  */
  mapOrDefault = {
    fn,
    value,
    default,
  }:
    if isEmpty value
    then default
    else fn value;

  /**
  Apply `fn` to `value` if not null, otherwise return `default`.

  Like `mapOrDefault` but with a null-only guard — empty strings and lists
  are still passed to `fn`.

  # Type
  ```nix
  mapOrNull :: { fn :: (a -> b), value :: a, default :: b } -> b
  ```

  # Examples
  ```nix
  mapOrNull { fn = s: s + "!"; value = null; default = "?"; }  # => "?"
  mapOrNull { fn = s: s + "!"; value = "";   default = "?"; }  # => "!"  (empty string transformed)
  ```
  */
  mapOrNull = {
    fn,
    value,
    default,
  }:
    if value == null
    then default
    else fn value;

  exports = {inherit orDefault orNull firstNonEmpty mapOrDefault mapOrNull;};
in
  exports // {_rootAliases = exports;}
