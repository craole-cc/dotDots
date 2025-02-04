{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Internal Imports
  inherit (config.DOTS)
    Enums
    Modules
    Sources
    Libraries
    # Users
    ;
  inherit (Libraries) fetchers;

  #| External Imports
  inherit (lib.attrsets)
    attrNames
    mapAttrs
    filterAttrs
    hasAttr
    ;
  inherit (lib.lists) length head;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) attrs;

  userAttrs = mapAttrs (_name: _path: Modules.user _name _path) Sources.user.configuration.attrs;

  userName = fetchers.user.name;
  usersHome = Sources.user.configuration.home;
  userConfigs = Enums.user.configuration;
  usersEnabled = rec {
    names = attrNames (filterAttrs (_name: _user: _user.enable) userAttrs);
    count = length names;
  };
  usersKnown = ''${concatStringsSep "\n      # " (
    map (_user: "config.dot.users." + _user + ".enable = true;") userConfigs
  )}'';
in
{
  options.DOTS = {
    Active.user = mkOption {
      description = "The current user configuration";
      default =
        if usersEnabled.count == 0 then
          throw ''
            Missing user configuration. Possible solutions:

            1. Enable one of the known users in your configuration file: 
                {
                  ${usersKnown}
                };

            2. Create a user configuration at either of the following locations: 
                [
                  ${toString usersHome + "/${userName}.nix"}
                  ${toString usersHome + "/${userName}/default.nix"}
                ]
                
               then enable it in your configuration file via:
                { config.dot.users.${userName}.enable = true; };
          ''
        else
          userAttrs.${head usersEnabled.names};
      type = attrs;
    };

    Alpha = mkOption {
      description = "The main administrator";
      default = "craole";
    };

    Users = mkOption { default = userAttrs; };
  };
}
