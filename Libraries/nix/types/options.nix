{
  _,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption mergeUniqueOption;
  inherit (lib.modules) mkIf mkMerge mkDefault mkForce;
  inherit (lib.types) mkOptionType str bool int float path;

  inherit (_.types.predicates) isString;
  customTypes = _.types.checks;

  __exports = {
    internal = {
      inherit
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
      mkOptionType = toOptionType;
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

  /**
  Bridges a `_.types.checks` type into a `lib.types`-compatible option type
  for use with `mkOption`. Accepts either a type attrset directly or a string
  name resolved from `_.types.checks`.

  Primitive types are mapped to their `lib.types` equivalents to preserve
  correct merge semantics. Constrained types fall back to `mkOptionType`
  with `mergeUniqueOption`.

  Primitive mappings: `"str"` | `"string"` → `str`, `"bool"` → `bool`,
  `"int"` → `int`, `"float"` → `float`, `"path"` → `path`.

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
      Creates an enable option that defaults to `true`.

      # Type
      `mkTrue :: String -> Option`

      # Arguments
      - `description`: Description string passed to `mkEnableOption`.

      # Examples
  ```nix
      mkTrue "my feature"
      # → mkOption { type = bool; default = true; description = "Whether to enable my feature."; }
  ```
  */
  mkTrue = description: mkEnableOption description // {default = true;};

  /**
      Creates an enable option that defaults to `false`.
      An alias of `mkEnableOption` provided for symmetry with `mkTrue`.

      # Type
      `mkFalse :: String -> Option`

      # Arguments
      - `description`: Description string passed to `mkEnableOption`.

      # Examples
  ```nix
      mkFalse "my feature"
      # → mkOption { type = bool; default = false; description = "Whether to enable my feature."; }
  ```
  */
  mkFalse = description: mkEnableOption description;

  /**
      Creates an enable option with a dynamic default derived from a condition.
      Useful when the default should depend on another value known at definition time.

      # Type
      `mkEnable :: { description :: String, condition :: Bool } -> Option`

      # Arguments
      - `description`: Description string passed to `mkEnableOption`.
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
    description,
    condition ? true,
  }:
    mkEnableOption description
    // {default = condition;};
in
  __exports.internal // {_rootAliases = __exports.external;}
