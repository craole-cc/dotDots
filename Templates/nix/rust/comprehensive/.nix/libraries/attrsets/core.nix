/**
  libraries/attrsets/core.nix

  Attrset utilities for lib.attrsets.
*/
{ lib }:
let
  inherit (lib.attrsets)
    attrValues
    getAttr
    hasAttr
    filterAttrs
    isAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) foldl;

  /**
    Conditionally create a single-attribute attrset.

    Returns an empty attrset when `condition` is false.

    # Type
    ```nix
    optionalAttr :: bool -> string -> any -> AttrSet
    ```

    # Examples
    ```nix
    optionalAttr true "foo" 42
    # => { foo = 42; }

    optionalAttr false "foo" 42
    # => {}
    ```

    # Returns
    `{ "${name}" = value; }` when `condition` is true, otherwise `{}`.
  */
  optionalAttr =
    condition: name: value:
    optionalAttrs condition { "${name}" = value; };

  /**
    Merge a set of attrsets recursively.

    Later nested values override earlier ones using `recursiveUpdate`.

    # Type
    ```nix
    recursiveAttrs :: AttrSet -> AttrSet
    ```

    # Examples
    ```nix
    recursiveAttrs {
      a = { services.nginx.enable = true; };
      b = { services.postgresql.enable = true; };
    }
    # => {
    #   services.nginx.enable = true;
    #   services.postgresql.enable = true;
    # }
    ```

    # Returns
    A single attrset produced by recursively merging all values in `conditions`.
  */
  recursiveAttrs =
    conditions: foldl recursiveUpdate { } (map (v: optionalAttrs (isAttrs v && v != { }) v) (attrValues conditions));

  updateAttrs =
    {
      name,
      value,
      default,
    }:
    recursiveUpdate default (optionalAttrs (hasAttr name value) (getAttr name value));

  /**
    Remove attributes whose values are `null`.

    Non-null falsey values such as `false`, `0`, and `""` are preserved.

    # Type
    ```nix
    compactAttrs :: AttrSet -> AttrSet
    ```

    # Examples
    ```nix
    compactAttrs {
      a = 1;
      b = null;
      c = "";
    }
    # => {
    #   a = 1;
    #   c = "";
    # }
    ```

    # Returns
    A copy of the input attrset with only `null`-valued attributes removed.
  */
  compactAttrs = filterAttrs (_: v: v != null);

  /**
    Map an attrset and drop attributes whose mapped values are `null`.

    Same notion of "drop" as `compactAttrs`.

    # Type
    ```nix
    mapFilterAttrs :: (string -> any -> any | null) -> AttrSet -> AttrSet
    ```

    # Examples
    ```nix
    mapFilterAttrs
    (name: value:
      if value == null
      then null
      else "${name}-${toString value}")
    {
      a = 1;
      b = null;
      c = 2;
    }
    # => {
    #   a = "a-1";
    #   c = "c-2";
    # }
    ```

    # Returns
    The mapped attrset with any attributes whose mapped value is `null` removed.
  */
  mapFilterAttrs = f: attrs: compactAttrs (mapAttrs f attrs);

  /**
    Convert attrset values to strings and drop `null` values.

    Useful for producing environment-variable attrsets.

    # Type
    ```nix
    toEnv :: AttrSet -> AttrSet
    ```

    # Examples
    ```nix
    toEnv {
      VERSION = 1;
      DEBUG = true;
      NULL = null;
    }
    # => {
    #   VERSION = "1";
    #   DEBUG = "true";
    # }
    ```

    # Returns
    An attrset of string values with any original `null` entries omitted.
  */
  toEnv = attrs: compactAttrs (mapAttrs (_: toString) attrs);
in
{
  inherit
    optionalAttr
    recursiveAttrs
    compactAttrs
    mapFilterAttrs
    updateAttrs
    toEnv
    ;
}
