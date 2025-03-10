{
  config,
  lib,
  ...
}: let
  dom = "dots";
  mod = "users";
  cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.types) attrs attrsOf;
  inherit (lib.attrsets) mapAttrs' filterAttrs;
  inherit (config.system) stateVersion;

  confirguration = mapAttrs' (key: val: {
    name = key;
    value = {
      home = {inherit stateVersion;};
      programs.home-manager.enable = true;
      wayland.windowManager = {inherit (val) hyprland;};
    };
  }) (filterAttrs (_: u: u.enable && u.isNormalUser) cfg);
in {
  options.${dom} = {
    test = mkOption {
      description = "Tests";
      default = {
        users = {
          options = cfg;
          config = confirguration;
        };
      };
      type = attrsOf attrs;
    };

    config = mkOption {
      description = "Modules to merge into the configuration";
      default = {
        home-manager.users = mapAttrs' (key: val: {
          name = key;
          value = {
            home = {inherit stateVersion;};
            programs.home-manager.enable = true;
            wayland.windowManager = {inherit (val) hyprland;};
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
