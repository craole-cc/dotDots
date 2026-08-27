{_, ...}: let
  exports = {
    inherit getEnvOr;
  };

  inherit (_.strings.access) getEnv;

  getEnvOr = key: default: let
    resolved = getEnv key;
  in
    if resolved != ""
    then resolved
    else default;
in
  exports // {__rootAliases = exports;}
