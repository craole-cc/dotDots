{
  config,
  lib,
  ...
}:
let
  dom = "dots";
  mod = "users";
  cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) toUpper substring stringLength;
  inherit (lib.types) attrs attrsOf submodule;
  inherit (lib.attrsets) mapAttrs' filterAttrs;

  capitalizeFirst = str: "${toUpper (substring 0 1 str)}${substring 1 (stringLength str - 1) str}";

  userOptions = {
    enable = mkEnableOption "Enable user";
    isNormalUser = mkOption {
      description = "Whether the user is a normal user";
      default = true;
    };
    groups = mkOption {
      description = "Additional user groups";
      default = [ "networkmanager" ];
    };
    description = mkOption {
      description = "User description";
      default = null;
    };
    password = mkOption {
      description = "Hashed password for the user";
      default = null;
    };
  };

  userConfiguration =
    userConfig:
    mapAttrs' (user: cfgUser: {
      name = user;
      value = {
        name = user;
        inherit (cfgUser) isNormalUser;
        extraGroups = cfgUser.groups;
        description =
          if cfgUser.description != null then
            cfgUser.description
          else if cfgUser.isNormalUser then
            "A user by the name of '${capitalizeFirst user}'"
          else
            "A system user dubbed '${user}'";
        hashedPassword = cfgUser.password;
      };
    }) (filterAttrs (_: cfgUser: cfgUser.enable && (cfgUser.isNormalUser or true)) userConfig);
in
{
  options.${dom} = {
    ${mod} = mkOption {
      description = "Users configuration";
      default = { };
      type = attrsOf (submodule {
        options = userOptions;
      });
    };

    test = mkOption {
      description = "Test suites for {{ dom }}";
      default = {
        users = {
          options = cfg;
          config = userConfiguration cfg;
        };
      };
      type = attrsOf attrs;
    };
  };

  config.users.users = userConfiguration cfg;
}
