{_, ...}: let
  __exports = {
    internal = {
      inherit toOptionType;
      mkType = toOptionType;
    };
    external = __exports.internal;
  };

  inherit
    (_.options)
    mkOptionType
    mergeUniqueOption
    str
    bool
    int
    float
    path
    ;
  inherit (_.types.predicates) isString;
  customTypes = _.types.checks;

  /**
  Bridges a `_.types.checks` type into a `lib.types`-compatible option type
  for use with `mkOption`. Accepts either a type attrset directly or a string
  name resolved from `_.types.checks`.

  Primitive types are mapped to their `lib.types` equivalents to preserve
  correct merge semantics. Constrained types fall back to `mkOptionType`
  with `mergeUniqueOption`.

  Primitive mappings: `"str"` | `"string"` → `str`, `"bool"` → `bool`,
  `"int"` → `int`, `"float"` → `float`, `"path"` → `path`.

  Note: `customTypeOrName` must be a `_.types.checks` attrset or a string key
  into it. Passing a bare `lib.types` value is not supported and will fail at
  evaluation time.

  # Type
  `toOptionType :: (CustomType | String) -> OptionType`

  # Arguments
  - `customTypeOrName`: A `_.types.checks` attrset, or a string key into `_.types.checks`.

  # Examples
  ```nix
    # Primitive via string — resolves to lib.types.str with correct merge
    mkOption { type = toOptionType "str"; }

    # Primitive via attrset
    mkOption { type = toOptionType _.types.checks.bool; }

    # Constrained type via string
    mkOption { type = toOptionType "port"; }

    # Constrained type via attrset
    mkOption { type = toOptionType (_.types.intBetween 1 100); }
  ```
  */
  toOptionType = customTypeOrName: let
    customType =
      if isString customTypeOrName
      then customTypes.${customTypeOrName}
      else customTypeOrName;
    primitives = {
      "string" = str;
      "str" = str;
      "bool" = bool;
      "int" = int;
      "float" = float;
      "path" = path;
    };
  in
    if primitives ? ${customType.type}
    then primitives.${customType.type}
    else
      mkOptionType {
        name = customType.type;
        description = customType.description or customType.type;
        check = customType.check;
        merge = mergeUniqueOption;
      };
in
  __exports.internal // {__rootAliases = __exports.external;}
