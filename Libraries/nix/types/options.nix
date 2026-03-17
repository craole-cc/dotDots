{lib, ...}: let
  inherit (lib.options) mkEnableOption;

  __exports = {
    internal = {
      inherit
        mkTrue
        mkFalse
        mkEnableOption
        ;
    };
    external = {
      mkEnableOptionTrue = mkTrue;
      mkEnableOptionFalse = mkFalse;
      inherit mkEnableOption;
    };
  };

  mkTrue = description: mkEnableOption description // {default = true;};
  mkFalse = description: mkEnableOption description;
in
  __exports.internal // {_rootAliases = __exports.external;}
