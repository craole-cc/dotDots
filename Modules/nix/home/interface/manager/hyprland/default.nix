{
  config,
  host,
  lib,
  lix,
  top,
  user,
  apps,
  keyboard,
  paths,
  ...
}: let
  dom = "home";
  mod = "hyprland";
  cfg = config.${top}.${dom}.${mod};

  # Use user.interface directly — already normalized per-user in mkUsers
  inherit (user.interface) windowManager;

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;

  addons = import ./addons {inherit lib mkMerge paths;};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = windowManager == "hyprland";};
    withAddons = mkOption {
      description = "Enable hyprland addons";
      default = true;
      type = bool;
    };
    withRules = mkOption {
      description = "Enable window rules";
      default = true;
      type = bool;
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = mkMerge [
      {
        enable = true;
        plugins = [];
      }
      (import ./settings {
        inherit host lib lix apps user keyboard mkMerge;
        withRules = cfg.withRules;
      })
      (import ./submaps {inherit mkMerge;})
    ];

    programs = mkIf cfg.withAddons addons.programs;
    services = mkIf cfg.withAddons addons.services;
  };
}
