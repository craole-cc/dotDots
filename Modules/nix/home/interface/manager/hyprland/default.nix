# Modules/nix/home/interface/manager/hyprland/default.nix
{
  config,
  host,
  lib,
  lix,
  top,
  user,
  apps,
  keyboard,
  ...
}: let
  dom = "home";
  mod = "hyprland";
  cfg = config.${top}.${dom}.${mod};

  iface = config.${top}.interface;

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = iface.wm == "hyprland";};
    withAddons = mkOption {
      description = "Enable hyprland addons (idle, lock, paper, etc.)";
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
      })
      (import ./submaps {inherit mkMerge;})
    ];

    programs =
      mkIf cfg.withAddons
      (import ./addons {inherit mkMerge;}).programs;

    services =
      mkIf cfg.withAddons
      (import ./addons {inherit mkMerge;}).services;
  };
}
