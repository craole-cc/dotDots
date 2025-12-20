{_, ...}: let
  exports = {
    # inherit
    # get
    # orNull
    # ;
    inherit (_.configuration.resolution) systems;
  };
in
  exports
  // {
    __doc = ''

    '';
    _rootAliases = {
    };
  }
