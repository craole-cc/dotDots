{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.lists.predicates) isList;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) splitString toPascal;
  inherit (_.attrsets.access) attrByPath;

  /**
      Normalize a field identifier into a path segment list.

      Dotted strings are split on `"."`. Lists pass through unchanged.

      # Type
  ```nix
      toPath :: string | [string] -> [string]
  ```

      # Examples
  ```nix
      toPath "a.b.c"      # => ["a" "b" "c"]
      toPath ["a" "b"]    # => ["a" "b"]
      toPath "simple"     # => ["simple"]
  ```
  */
  toPath = field:
    if isList field
    then field
    else splitString "." field;

  /**
      Safely read a possibly-nested field from an attribute set, returning
      `default` when any path segment is absent.

      `field` may be a dotted string or a pre-split list; both forms are
      normalized before traversal.

      # Type
  ```nix
      toValue :: {
        field   :: string | [string],
        default :: a,               # optional, default null
      } -> AttrSet -> a | null
  ```

      # Examples
  ```nix
      toValue { field = "a.b"; } { a = { b = 42; }; }   # => 42
      toValue { field = "a.b"; } { a = {}; }             # => null
      toValue { field = "x"; default = 0; } {}           # => 0
  ```
  */
  toValue = {
    field,
    default ? null,
  }: app:
    attrByPath (
      if isList field
      then field
      else splitString "." field
    )
    default
    app;

  /**
      Derive a camelCase identifier from a field path, with optional prefix
      and suffix.

      The field is normalized to a list, joined with `"-"`, then passed
      through `toPascal` before the prefix is prepended and the suffix
      appended.

      # Type
  ```nix
      toName :: {
        prefix :: string,    # optional, default ""
        field  :: string | [string],
        suffix :: string,    # optional, default ""
      } -> string
  ```

      # Examples
  ```nix
      toName { field = "color"; }                        # => "color"
      toName { prefix = "by"; field = "color"; }         # => "byColor"
      toName { prefix = "by"; field = "a.b"; }           # => "byAB"
      toName { prefix = "by"; field = ["a" "b"]; suffix = "Index"; }
      # => "byABIndex"
  ```
  */
  toName = {
    prefix ? "",
    field,
    suffix ? "",
  }: let
    normalized = concatStringsSep "-" (
      if isList field
      then field
      else splitString "." field
    );
  in
    prefix + toPascal normalized + suffix;
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Primitive field accessors (Layer 1).

      Provides the core operations for normalizing field paths, reading values
      from nested attribute sets, and deriving camelCase names from field
      identifiers. All higher-level modules depend on these primitives.
    '';

    functions = {inherit toPath toValue toName;};
  }
