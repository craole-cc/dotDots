{_, ...}: let
  meta = let
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
        asPath
        toValue
        toName
        normalizeOptional
        normalizeList
        keysFromOptional
        keysFromMembers
        ;
    };
    exports = {
      local = functions;
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.lists.predicates) isList;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concatStringsSep optionalString;
  inherit (_.strings.transformation) splitString toPascal;
  inherit (_.attrsets.access) attrByPath attrValues;

  /**
      Normalize a field identifier into a path segment list.

      Dotted strings are split on `"."`. Lists pass through unchanged.

      # Type
  ```nix
      asPath :: string | [string] -> [string]
  ```

      # Examples
  ```nix
      asPath "a.b.c"      # => ["a" "b" "c"]
      asPath ["a" "b"]    # => ["a" "b"]
      asPath "simple"     # => ["simple"]
  ```
  */
  asPath = field:
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
  }: app: attrByPath (asPath field) default app;

  /**
      Derive a PascalCase-style identifier fragment from a field path, with
      optional naming kind, prefix, and suffix.

      The field is normalized to a list, joined with `"-"`, then passed
      through `toPascal`. When `kind = "group"` and `prefix` is omitted,
      the default prefix is `"by"`.

      # Type
  ```nix
      toName :: {
        field  :: string | [string],
        kind   :: string,    # optional, default "plain"
        prefix :: string,    # optional, default depends on kind
        suffix :: string,    # optional, default ""
      } -> string
  ```

      # Examples
  ```nix
      toName { field = "color"; }                          # => "Color"
      toName { kind = "group"; field = "color"; }         # => "byColor"
      toName { prefix = "is"; field = "enabled"; }        # => "isEnabled"
      toName { kind = "group"; field = "config.lang"; }   # => "byConfigLang"
      toName { prefix = "by"; field = ["a" "b"]; suffix = "Index"; }
      # => "byABIndex"
  ```
  */
  toName = {
    field,
    kind ? "plain",
    prefix ? null,
    suffix ? "",
  }: let
    normalized = concatStringsSep "-" (asPath field);
    resolvedPrefix =
      if prefix != null
      then prefix
      else optionalString (kind == "group") "by";
  in
    resolvedPrefix + toPascal normalized + suffix;

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
      filter (value: value != null) (map (item: normalizeOptional (toValue {inherit field;} item)) (attrValues set))
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
      builtins.concatMap (
        item:
          normalizeList (
            toValue {
              inherit field;
              default = [];
            }
            item
          )
      ) (attrValues set)
    );
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
