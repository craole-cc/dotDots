{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = __exports.internal;
  };

  inherit (_.applications.enums) categories channels families;
  inherit (_.applications.construction) mkSubsystem;
  path = ./.data;
  all = mkSubsystem {inherit path categories channels families;};
in
  __exports.internal // {_rootAliases = __exports.external;}
