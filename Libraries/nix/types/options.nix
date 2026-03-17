{lib, ...}: let
  inherit (lib.options) mkEnableOption;

  __exports = {
    internal = {inherit mkTrue;};
    external = {mkEnableOptionTrue = mkTrue;};
  };

  mkTrue = description: mkEnableOption description // {default = true;};
in
  __exports.internal // {_rootAliases = __exports.external;}
