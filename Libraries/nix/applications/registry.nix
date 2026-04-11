{_, ...}: let
  __doc = ''
    Application registry (Layer 3).

    Loads the full application registry from the `.data` directory and
    exposes it as a single attribute set.

    Depends on: _.applications.construction
  '';

  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  __imports = {
    inherit (_.applications.construction) importRegistry;
  };

  all = with __imports; importRegistry ./.data;
in
  __exports.internal
  // {
    _rootAliases = __exports.external;
    inherit __doc;
  }
