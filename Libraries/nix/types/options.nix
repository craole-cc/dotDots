{lib, ...}: let
  inherit (lib.options) mkEnableOption;

  __exports = {
    internal = {
      inherit
        mkTrue
        mkFalse
        mkEnable
        ;
    };
    external = {
      mkEnableOptionTrue = mkTrue;
      mkEnableOptionFalse = mkFalse;
      mkEnableOption' = mkEnable;
    };
  };

  mkTrue = description: mkEnableOption description // {default = true;};
  mkFalse = description: mkEnableOption description;
  mkEnable = description: condition: mkEnableOption description // {default = condition;};
in
  __exports.internal // {_rootAliases = __exports.external;}
