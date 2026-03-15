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

  inherit (config.OSConfig.${top}.interface) windowManager;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
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

  config =
    mkIf cfg.enable {
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
    }
    // optionalAttrs cfg.withAddons (let
      addons = import ./addons {inherit lib mkMerge paths;};
    in {
      inherit (addons) programs services;
    });
}
