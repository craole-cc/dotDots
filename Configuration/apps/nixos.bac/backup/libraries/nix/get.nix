{ config, lib, ... }:
let
  inherit (builtins) getEnv concatStringsSep;
  inherit (lib)
    types
    mkOption
    elem
    substring
    ;
  inherit (types) listOf str attrs;
  inherit (config) dots networking;
  inherit (dots.lib) enums;

  mod = "get";
  cfg = dots.lib.${mod};
  src = dots.sources.internal;
in
{
  options.dots.lib.${mod} = {

    hostName = mkOption {
      description = "The current hostname";
      default = networking.hostName;
      type = str;
    };

    host = mkOption {
      description = "The current host configuration";
      default =
        if elem cfg.hostName enums.host.name then
          dots.hosts.${cfg.hostName}
        else
          throw ''
            Unknown Host: Add the configuration for `${cfg.hostName}` to the hosts directory.

            Missing Config: ${toString (src.host + "/" + cfg.hostName + "/default.nix")}
                  Template: ${toString src.template.host}
               Known Hosts: [ ${concatStringsSep " " (map (x: ''"${x}"'') enums.host.name)} ]
          '';
      example = src.template.host;
      type = attrs;
    };

    userName = mkOption {
      description = "The current username";
      default = getEnv "USER";
      type = str;
    };

    # user = mkOption {
    #   description = "The current host configuration";
    #   default =
    #     if elem cfg.userName enums.user.name then
    #       dots.users.${cfg.userName}
    #     else
    #       throw ''
    #         Unknown Host: Add the configuration for `${cfg.userName}` to the hosts directory.

    #         Missing Config: ${toString (src.user + "/" + cfg.userName + "/default.nix")}
    #               Template: ${toString src.template.user}
    #             Known Hosts: [ ${concatStringsSep " " (map (x: ''"${x}"'') cfg.users)} ]
    #       '';
    #   example = src.template.user;
    #   type = attrs;
    # };

    stateVersion = mkOption {
      description = "The NixOS state version of the current host";
      default = substring 0 5 (cfg.host.version);
      type = str;
    };
  };
}
