{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.lists.predicates) isList;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) splitString toPascal;
  inherit (_.attrsets.access) attrByPath attrValues;

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
    attrByPath (toPath field) default app;

  /**
      Derive a PascalCase-style identifier fragment from a field path, with
      optional prefix and suffix.

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
      toName { field = "color"; }                        # => "Color"
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
    normalized = concatStringsSep "-" (toPath field);
  in
    prefix + toPascal normalized + suffix;

  /**
      Normalize an optional scalar value.

      Treats `null`, the empty string, and the sentinel string `"none"` as
      absent values and returns `null`. All other values pass through
      unchanged.

      # Type
  ```nix
      normalizeOptional :: a | null -> a | null
  ```

      # Examples
  ```nix
      normalizeOptional null      # => null
      normalizeOptional ""        # => null
      normalizeOptional "none"    # => null
      normalizeOptional "beta"    # => "beta"
  ```
  */
  normalizeOptional = value:
    if value == null || value == "" || value == "none"
    then null
    else value;

  /**
      Normalize a list-valued field.

      Non-lists become `[]`. For lists, removes `null`, the empty string, and
      the sentinel string `"none"`.

      # Type
  ```nix
      normalizeList :: [a] | b -> [a]
  ```

      # Examples
  ```nix
      normalizeList ["a" null "" "none" "b"]   # => ["a" "b"]
      normalizeList null                        # => []
      normalizeList "a"                         # => []
  ```
  */
  normalizeList = values:
    if isList values
    then filter (value: value != null && value != "" && value != "none") values
    else [];

  /**
      Derive the unique normalized scalar values present at `field` across an
      attribute set of records.

      Missing values and values normalized to `null` are omitted. This is
      useful for building canonical query key spaces such as all known
      maturities or protocols.

      # Type
  ```nix
      keysFromOptional :: string | [string] -> AttrSet -> [a]
  ```

      # Examples
  ```nix
      keysFromOptional "maturity" {
        a = { maturity = "stable"; };
        b = { maturity = "beta"; };
        c = { maturity = "none"; };
      }
      # => ["stable" "beta"]
  ```
  */
  keysFromOptional = field: set:
    unique (
      filter
      (value: value != null)
      (map (item: normalizeOptional (toValue {inherit field;} item)) (attrValues set))
    );

  /**
      Derive the unique normalized member values present at `field` across an
      attribute set of records.

      The field is expected to be list-valued; missing or non-list values are
      treated as empty lists. This is useful for building canonical member
      domains such as capabilities, scopes, or protocols.

      # Type
  ```nix
      keysFromMembers :: string | [string] -> AttrSet -> [a]
  ```

      # Examples
  ```nix
      keysFromMembers "capabilities" {
        a = { capabilities = ["sync" "tabs"]; };
        b = { capabilities = ["tabs" "none"]; };
        c = {};
      }
      # => ["sync" "tabs"]
  ```
  */
  keysFromMembers = field: set:
    unique (
      builtins.concatMap
      (item:
        normalizeList (toValue {
            inherit field;
            default = [];
          }
          item))
      (attrValues set)
    );
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Primitive field and value helpers (Layer 1).

      Provides the core operations for normalizing field paths, reading values
      from nested attribute sets, deriving exported names, normalizing
      optional and list-valued fields, and extracting canonical key domains
      from application records.

      Higher-level selector and query-builder modules should depend on these
      primitives rather than reimplementing normalization or key discovery.
    '';

    functions = {
      inherit
        toPath
        toValue
        toName
        normalizeOptional
        normalizeList
        keysFromOptional
        keysFromMembers
        ;
    };
  }
