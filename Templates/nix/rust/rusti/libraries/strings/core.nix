/**
libraries/strings/core.nix

String utilities for lib.strings.
*/
{lib}: let
  inherit (lib.lists) filter map;
  inherit
    (lib.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    ;

  /**
  Ensure a string starts with `prefix`.

  # Type
  ```nix
  ensurePrefix :: string -> string -> string
  ```

  # Examples
  ```nix
  ensurePrefix "/" "tmp/cache"
  # => "/tmp/cache"

  ensurePrefix "/" "/tmp/cache"
  # => "/tmp/cache"
  ```

  # Returns
  `value` unchanged when it already starts with `prefix`, otherwise `prefix + value`.
  */
  ensurePrefix = prefix: value:
    if hasPrefix prefix value
    then value
    else prefix + value;

  /**
  Ensure a string ends with `suffix`.

  # Type
  ```nix
  ensureSuffix :: string -> string -> string
  ```

  # Examples
  ```nix
  ensureSuffix ".nix" "default"
  # => "default.nix"

  ensureSuffix ".nix" "default.nix"
  # => "default.nix"
  ```

  # Returns
  `value` unchanged when it already ends with `suffix`, otherwise `value + suffix`.
  */
  ensureSuffix = suffix: value:
    if hasSuffix suffix value
    then value
    else value + suffix;

  /**
  Convert null and empty strings to `null`.

  Input values are stringified before the emptiness check.

  # Type
  ```nix
  nonEmptyOrNull :: any | null -> string | null
  ```

  # Examples
  ```nix
  nonEmptyOrNull null
  # => null

  nonEmptyOrNull 42
  # => "42"
  ```

  # Returns
  `null` for null or empty input, otherwise the stringified value.
  */
  nonEmptyOrNull = value:
    if value == null
    then null
    else let
      stringValue = toString value;
    in
      if stringValue == ""
      then null
      else stringValue;

  /**
  Join non-empty string parts with `separator`.

  Null and empty parts are dropped after stringification.

  # Type
  ```nix
  concatNonEmpty :: string -> [any | null] -> string
  ```

  # Examples
  ```nix
  concatNonEmpty "/" ["var" "" null "log"]
  # => "var/log"
  ```

  # Returns
  The separator-joined string of all non-empty parts.
  */
  concatNonEmpty = separator: parts:
    concatStringsSep separator (
      filter (part: part != null) (map nonEmptyOrNull parts)
    );

  /**
  Join non-empty parts into a newline-delimited string.

  # Type
  ```nix
  lines :: [any | null] -> string
  ```

  # Examples
  ```nix
  lines ["alpha" "" null "beta"]
  # => "alpha\nbeta"
  ```

  # Returns
  A newline-delimited string built from the non-empty parts.
  */
  lines = concatNonEmpty "\n";

  /**
  Join non-empty parts into a space-delimited string.

  # Type
  ```nix
  words :: [any | null] -> string
  ```

  # Examples
  ```nix
  words ["cargo" "" null "test"]
  # => "cargo test"
  ```

  # Returns
  A space-delimited string built from the non-empty parts.
  */
  words = concatNonEmpty " ";
in {
  inherit
    ensurePrefix
    ensureSuffix
    nonEmptyOrNull
    concatNonEmpty
    lines
    words
    ;
}
