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

  wm = user.interface.windowManager or null;

  inherit (lib.modules) mkIf mkMerge mkForce mkDefault;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = wm == "hyprland";};
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
      {enable = true;}
      (import ./settings {
        inherit host lib lix apps user keyboard mkMerge;
        withRules = cfg.withRules;
      })
      (import ./submaps {inherit mkMerge;})
    ];

    programs =
      mkIf cfg.withAddons
      (import ./addons {inherit lib mkMerge paths;}).programs;

    services =
      mkIf cfg.withAddons
      (import ./addons {inherit lib mkMerge paths;}).services;
  };
}
