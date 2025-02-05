{
  config,
  lib,
  ...
}:
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
in
{
  options.${dom} = {
    test = mkOption {
      description = "Tests";
      default = {
        users = cfg;
      };
      type = attrsOf attrs;
    };

    config = mkOption {
      description = "Modules to merge into the configuration";
      default = {
        users.users = mapAttrs' (key: val: {
          name = key;
          value = {
            extraGroups = val.groups;
            description =
              if val.description != null then
                val.description
              else if val.isSystemUser then
                "A system user dubbed '${key}'"
              else
                "A user by the name of '${capitalizeFirst key}'";
            hashedPassword = val.password;
            isNormalUser = !val.isSystemUser;
            isSystemUser = val.isSystemUser;
          };
        }) (filterAttrs (_: u: u.enable) cfg);

        home-manager.users = mapAttrs' (key: val: {
          name = key;
          value = {
            home = { inherit stateVersion; };
            programs.home-manager.enable = true;
            wayland.windowManager = { inherit (val) hyprland; };
          };
        }) (filterAttrs (_: u: u.enable && u.isNormalUser) cfg);
      };
      type = attrsOf attrs;
    };
  };

  config = {
    inherit (config.${dom}.config) users home-manager;
  };
}
