{
  _,
  lib,
  ...
}: let
  __exports = {
    internal = {
      inherit
        mkEnumOption
        toOptionType
        mkDefault
        mkEnable
        mkFalse
        mkForce
        mkIf
        mkMerge
        mkOption
        mkTrue
        ;
      mkType = toOptionType;
    };
    external =
      __exports.internal
      // {
        mkEnableOptionTrue = mkTrue;
        mkEnableOptionFalse = mkFalse;
        mkEnableOption' = mkEnable;
      };
  };

  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.options) mkOption mergeUniqueOption;
  inherit (lib.modules) mkIf mkMerge mkDefault mkForce;
  inherit
    (lib.types)
    mkOptionType
    enum
    str
    bool
    int
    float
    path
    nullOr
    ;

  inherit (_.lists.generators) mkEnum;
  inherit (_.types.predicates) isString isAttrs;
  customTypes = _.types.checks;

  # Omits the `description` key entirely when null, so doc generators and
  # `nixos-option` see an absent field rather than an explicit null.
  optionalDesc = {description}:
    optionalAttrs
    (description != null)
    {inherit description;};

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
    // optionalDesc {inherit description;};

  /**
  Creates a `mkOption` backed by an enum type, with optional nullability.
  Accepts either a pre-built enum attrset (from `mkEnum`) or a plain list of
  values, which will be passed to `mkEnum` automatically.

  When `input` is a pre-built enum attrset containing a `nullable` field, that
  value takes precedence over the `nullable` argument.

  # Type
  `mkEnumOption :: { input :: ([String] | EnumType), description :: String?,
                    default :: Any?, nullable :: Bool } -> Option`

  # Arguments
  - `input`: A list of valid string values, or a pre-built `mkEnum` attrset
    with an `allValues` field.
  - `description`: Option description forwarded to `mkOption`. Optional.
  - `default`: Default value. Defaults to `null`.
  - `nullable`: Whether to wrap the type in `nullOr`. Ignored when `input` is
    a pre-built enum that already carries a `nullable` field. Defaults to `true`.

  # Examples
  ```nix
    # From a plain list
    mkEnumOption {
      description = "log verbosity";
      input       = [ "debug" "info" "warn" "error" ];
      default     = "info";
      nullable    = false;
    }

    # From a pre-built enum (nullable derived from the enum itself)
    mkEnumOption {
      input = mkEnum { values = [ "a" "b" "c" ]; nullable = false; };
    }
  ```
  */
  mkEnumOption = {
    input,
    description ? null,
    default ? null,
    nullable ? true,
  }: let
    e =
      if isAttrs input && input ? allValues
      then input
      else
        mkEnum {
          values = input;
          inherit nullable;
        };
    isNullable = e.nullable or nullable;
  in
    mkOption {
      inherit default;
      type =
        if isNullable
        then nullOr (enum e.allValues)
        else enum e.allValues;
    }
    // optionalDesc {inherit description;};

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
in
  __exports.internal // {_rootAliases = __exports.external;}
