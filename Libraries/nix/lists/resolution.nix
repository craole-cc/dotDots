{_, ...}: let
  exports = {
    # inherit
    # get
    # orNull
    # ;
    inherit (_.modules.resolution) systems;
  };
in
  exports
  // {
    __doc = ''

    '';
    _rootAliases = {
    };
  }
