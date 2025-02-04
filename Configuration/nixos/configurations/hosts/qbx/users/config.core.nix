{ config, lib, ... }:
let
  dom = "dots";
  mod = "users";
  cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.strings) toUpper substring stringLength;
  inherit (lib.types) attrs attrsOf;
  inherit (lib.attrsets) mapAttrs' filterAttrs;
  inherit (config.system) stateVersion;

  capitalizeFirst = str: "${toUpper (substring 0 1 str)}${substring 1 (stringLength str - 1) str}";

  coreConfirguration = mapAttrs' (key: val: {
    name = key;
    value = {
      inherit (val) isNormalUser isSystemUser;
      extraGroups = val.groups;
      description =
        if val.description != null then
          val.description
        else if val.isNormalUser then
          "A user by the name of '${capitalizeFirst key}'"
        else
          "A system user dubbed '${key}'";
      hashedPassword = val.password;
    };
  }) (filterAttrs (_: u: u.enable) cfg);

in
{
  options.${dom} = {
    test = mkOption {
      description = "Tests";
      default = {
        users = {
          options = cfg;
          config = coreConfirguration;
        };
      };
      type = attrsOf attrs;
    };

    config = mkOption {
      description = "Modules to merge into the configuration";
      default = {
        users.users = coreConfirguration;
        home-manager.users = homeConfirguration;
      };
      type = attrsOf attrs;
    };
  };

  config = {
    inherit (config.${dom}.config) users home-manager;
  };
}
