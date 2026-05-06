{
  lib,
  paths,
  ...
}: let
  inherit (lib.lists) filter flatten map toList;
  inherit
    (lib.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    isStringLike
    hasInfix
    splitString
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
  concatNonEmpty = {
    separator ? "",
    parts ? [],
  }:
    concatStringsSep separator (
      filter
      (part: part != null)
      (map nonEmptyOrNull parts)
    );

  toPathString = {
    root ? paths.flake,
    stem ? null,
  }: let
    separator = "/";
    mkParts = value:
      flatten (map (
        part:
          if isStringLike part && hasInfix separator part
          then splitString separator part
          else [part]
      ) (toList value));
    parts = (mkParts root) ++ (mkParts stem);
  in
    concatNonEmpty {inherit separator parts;};

  /**
  Join non-empty parts into a newline-delimited string.

  # Type
  ```nix
  toLines :: [any | null] -> string
  ```

  # Examples
  ```nix
  toLines ["alpha" "" null "beta"]
  # => "alpha\nbeta"
  ```

  # Returns
  A newline-delimited string built from the non-empty parts.
  */
  toLines = parts:
    concatNonEmpty {
      separator = "\n";
      inherit parts;
    };

  /**
  Join non-empty parts into a space-delimited string.

  # Type
  ```nix
  toWords :: [any | null] -> string
  ```

  # Examples
  ```nix
  toWords ["alpha" "" null "beta"]
  # => "alpha beta"
  ```

  # Returns
  A space-delimited string built from the non-empty parts.
  */
  toWords = parts:
    concatNonEmpty {
      separator = " ";
      inherit parts;
    };
in {
  inherit
    ensurePrefix
    ensureSuffix
    nonEmptyOrNull
    concatNonEmpty
    toLines
    toWords
    toPathString
    ;
  toStringPath = toPathString;
}
