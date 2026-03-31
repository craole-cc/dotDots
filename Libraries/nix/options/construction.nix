{_, ...}: let
  __exports = {
    internal = {
      inherit mkEnable mkTrue mkFalse mkEnum;
      mkEnableOption' = mkEnable;
      mkEnumOption = mkEnum;
    };
    external = {
      mkEnableOptionTrue = mkTrue;
      mkEnableOptionFalse = mkFalse;
      mkEnableOption = mkEnable;
      mkEnumOption = mkEnum;
    };
  };

  inherit (_.options.construction) mkOption;
  inherit (_.types.primitives) bool;
  inherit (_.types.combinators) enum nullOr;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.types.predicates) isAttrs;
  mkEnumData = _.lists.construction.mkEnum;

  # Omits the `description` key entirely when null, so doc generators and
  # `nixos-option` see an absent field rather than an explicit null.
  optionalDesc = description:
    optionalAttrs (description != null) {inherit description;};

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
  Creates a `mkOption` backed by an enum type, with optional nullability.
  Accepts either a pre-built enum attrset (from `mkEnum`) or a plain list of
  values, which will be passed to `mkEnum` automatically.

  When `input` is a pre-built enum attrset containing a `nullable` field, that
  value takes precedence over the `nullable` argument.

  # Type
  `mkEnum :: { input :: ([String] | EnumType), description :: String?,
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
    mkEnum {
      description = "log verbosity";
      input       = [ "debug" "info" "warn" "error" ];
      default     = "info";
      nullable    = false;
    }

    # From a pre-built enum (nullable derived from the enum itself)
    mkEnum {
      input = mkEnum { values = [ "a" "b" "c" ]; nullable = false; };
    }
  ```
  */
  mkEnum = {
    input,
    description ? null,
    default ? null,
    nullable ? true,
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
  in
    mkOption {
      inherit default;
      type =
        if isNullable
        then nullOr (enum e.allValues)
        else enum e.allValues;
    }
    // optionalDesc description;
in
  __exports.internal // {_rootAliases = __exports.external;}
