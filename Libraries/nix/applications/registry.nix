{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  inherit (_.applications.construction) importRegistry;

  all = importRegistry ./.data;
in
  __exports.internal // {_rootAliases = __exports.external;}
