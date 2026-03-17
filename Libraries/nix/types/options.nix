{lib, ...}: let
  inherit (lib.options) mkEnableOption;

  __exports = {
    internal = {inherit mkTrue mkFalse;};
    external = {
      mkEnableOptionTrue = mkTrue;
      mkEnableOptionFalse = mkFalse;
    };
  };

  mkTrue = description: mkEnableOption description // {default = true;};
  mkFalse = description: mkEnableOption description;
in
  __exports.internal // {_rootAliases = __exports.external;}
