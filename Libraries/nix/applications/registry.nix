{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  inherit (_.applications.enums) categories channels families;
  inherit (_.applications.construction) mkRegistry;

  all = mkRegistry {
    data = _.filesystem.importers.importAllMerged ./.data {};
    inherit categories channels families;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
