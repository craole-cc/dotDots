{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  inherit (_.applications.construction) mkRegistry;
  inherit (_.applications.enums) categories channels families;
  inherit (_.filesystem.importers) importAllMerged;

  all = mkRegistry {
    data = importAllMerged ./.data {};
    inherit categories channels families;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
