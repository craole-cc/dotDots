{lib, ...}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkMerge mkDefault mkForce;

  __exports = {
    internal = {
      inherit
        mkTrue
        mkFalse
        mkEnable
        mkIf
        mkMerge
        mkDefault
        mkForce
        ;
    };
    external =
      __exports.internal
      // {
        mkEnableOptionTrue = mkTrue;
        mkEnableOptionFalse = mkFalse;
        mkEnableOption' = mkEnable;
      };
  };

  mkTrue = description: mkEnableOption description // {default = true;};
  mkFalse = description: mkEnableOption description;
  mkEnable = {
    description,
    condition ? true,
  }:
    mkEnableOption description
    // {default = condition;};
in
  __exports.internal // {_rootAliases = __exports.external;}
