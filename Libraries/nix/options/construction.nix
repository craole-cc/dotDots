{_, ...}: let
  __exports = {
    internal = {
      inherit
        mkEnable
        mkTrue
        mkFalse
        mkEnum
        mkEnums
        toOptionType
        ;
      inherit
        (aliases)
        # mkEnableOption'
        # mkOptionEnable
        mkOptionEnum
        mkOptionEnums
        # mkOptionFalse
        # mkOptionTrue
        # mkOptionType'
        mkType
        ;
    };
    external = {
      inherit
        (aliases)
        mkEnableOption'
        mkOptionEnable
        mkOptionEnum
        mkOptionEnums
        mkOptionFalse
        mkOptionTrue
        mkOptionType'
        ;
    };
  };

  aliases = {
    mkEnableOption' = mkEnable;
    mkOptionEnable = mkEnable;
    mkOptionEnum = mkEnum;
    mkOptionEnums = mkEnums;
    mkOptionFalse = mkFalse;
    mkOptionTrue = mkTrue;
    mkOptionType' = toOptionType;
    mkType = toOptionType;
  };

  inherit (_.attrsets.construction) optionalAttrs;
  inherit
    (_.options.construction)
    mkOption
    mergeUniqueOption
    mkOptionType
    ;
  inherit (_.types.combinators) enum listOf nullOr;
  inherit
    (_.types.primitives)
    str
    bool
    int
    float
    path
    ;
  inherit (_.types.predicates) isAttrs isString;
  customTypes = _.types.checks;
  mkEnumData = _.lists.construction.mkEnum;

  # Omits the `description` key entirely when null, so doc generators and
  # `nixos-option` see an absent field rather than an explicit null.
  optionalDesc = description: optionalAttrs (description != null) {inherit description;};

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
    primitives.${
      customType.type
    } or (mkOptionType {
      name = customType.type;
      description = customType.description or customType.type;
      inherit (customType) check;
      merge = mergeUniqueOption;
    });

  /**
  Creates a boolean enable option whose default is derived from a condition.
  Useful when the default should depend on another value known at definition time.

  `mkTrue` and `mkFalse` are convenience wrappers over this function for the
  common `true` / `false` cases.

  # Type
  `mkEnable :: { description :: String?, condition :: Bool } -> Option`

  # Arguments
  - `description`: Human-readable description forwarded to `mkOption`. Optional.
  - `condition`: Boolean expression used as the default value. Defaults to `true`.

  # Examples
  ```nix
    mkEnable {
      description = "hardware acceleration";
      condition   = config.hardware.gpu.enable;
    }

    # With no condition, defaults to true
    mkEnable { description = "some feature"; }
  ```
  */
  mkEnable = {
    description ? null,
    condition ? true,
  }:
    mkOption {
      default = condition;
      type = bool;
    }
    // optionalDesc description;

  /**
  Creates a boolean enable option that defaults to `true`.

  # Type
  `mkTrue :: String? -> Option`

  # Arguments
  - `description`: Human-readable description forwarded to `mkOption`. Optional.

  # Examples
  ```nix
    mkTrue "my feature"
    # → mkOption { type = bool; default = true; description = "my feature"; }
  ```
  */
  mkTrue = description:
    mkEnable {
      inherit description;
      condition = true;
    };

  /**
  Creates a boolean enable option that defaults to `false`.

  # Type
  `mkFalse :: String? -> Option`

  # Arguments
  - `description`: Human-readable description forwarded to `mkOption`. Optional.

  # Examples
  ```nix
    mkFalse "my feature"
    # → mkOption { type = bool; default = false; description = "my feature"; }
  ```
  */
  mkFalse = description:
    mkEnable {
      inherit description;
      condition = false;
    };

  /**
  Creates a `mkOption` backed by an enum type, with optional nullability and
  list support. Accepts either a pre-built enum attrset (from
  `_.lists.construction.mkEnum`) or a plain list of values, which will be
  passed through automatically.

  When `input` is a pre-built enum attrset containing a `nullable` field, that
  value takes precedence over the `nullable` argument. When `many = true`, the
  option holds a list of enum values instead of a single value, and `default`
  falls back to `[]` instead of `null`.

  Exported as `mkOptionEnum` (single) and `mkOptionEnums` (list) for
  call-site clarity, but both resolve to this function.

  # Type
  `mkEnum :: { input :: ([String] | EnumType), description :: String?,
               default :: Any?, nullable :: Bool, many :: Bool } -> Option`

  # Arguments
  - `input`: A list of valid string values, or a pre-built `mkEnum` attrset
    with an `allValues` field.
  - `description`: Option description forwarded to `mkOption`. Optional.
  - `default`: Default value. Defaults to `null` when `many = false`, `[]`
    when `many = true`.
  - `nullable`: Whether to wrap the element type in `nullOr`. Ignored when
    `input` is a pre-built enum that already carries a `nullable` field.
    Defaults to `true`.
  - `many`: When `true`, wraps the type in `listOf`, producing a
    multi-value option. Defaults to `false`.

  # Examples
  ```nix
    # Single value from a plain list
    mkOptionEnum {
      description = "log verbosity";
      input       = [ "debug" "info" "warn" "error" ];
      default     = "info";
      nullable    = false;
    }

    # Single value from a pre-built enum (nullable derived from the enum)
    mkOptionEnum {
      input = sh.enums.system;
    }

    # List of values — equivalent to mkOptionEnums
    mkOptionEnum {
      description = "shell enhancements";
      input       = sh.enums.enhancements;
      default     = [ "atuin" "zoxide" "fzf" ];
      many        = true;
    }

    # Via the mkOptionEnums alias
    mkOptionEnums {
      description = "shell enhancements";
      input       = sh.enums.enhancements;
      default     = [ "atuin" "zoxide" "fzf" ];
    }
  ```
  */
  mkEnum = {
    input,
    description ? null,
    default ? null,
    nullable ? true,
    many ? false, # ← false = single value, true = listOf
  }: let
    e =
      if isAttrs input && input ? allValues
      then input
      else
        mkEnumData {
          values = input;
          inherit nullable;
        };
    isNullable = e.nullable or nullable;
    elemType =
      if isNullable
      then nullOr (enum e.allValues)
      else enum e.allValues;
  in
    mkOption {
      default =
        if many
        then
          (
            if default == null
            then []
            else default
          )
        else default;
      type =
        if many
        then listOf elemType
        else elemType;
    }
    // optionalDesc description;

  mkEnums = args: mkEnum (args // {many = true;});
in
  __exports.internal // {__rootAliases = __exports.external;}
